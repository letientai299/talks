# Functional Option

A pattern to implement scalable library APIs.

<!-- slide -->

## Disclamer

- I'm not the author of the pattern introduce here. I just show a way to apply
  it when building package.

- Code show in this slide is faked, and the style is not nice due to spacing
  constraint in a slide.

Notes: I learn it from Rob Pike Self-referential functions articles And using
the name Functional Option popularized by Dave Cheney because it's easier to
remember.

<!-- slide -->

## Content

- Problem
- Example
- Ideas
- Applications

<!-- slide -->

## The problem

- Package/sevice/function usually starts smalls

- More and more features:
  - Its APIs become more and more complex
  - Next features become harder to implement.

<!-- slide -->

## Example: item loading function

Its starts simple

```go
func (dm *Loader) load(shopid, itemid int64) Item {...}
```

<!-- slide -->

Then, we need to find deleted items

```go
func (dm *Loader) Load(
  shopid, itemid int64,
  needDeleted bool,
) Item {...}
```

<!-- slide -->

Then, we need models as well, to reduce requests

```go
func (dm *Loader) Load(
  shopid, itemid int64,
  needModels, needDeleted bool,
) Item {...}
```

<!-- slide -->

Its usage be like:

```go
func main() {
  dm := &Loader{}
  _ = dm.Load(123, 4567, true, false)
}
```

Code readers:

_Hey, is this load deleted item without models or ...?
Nevermind, let's check that function again._

<!-- slide -->

<div id="left">

We're not done yet!

We need some flag to:

- Read from?
  - slave
  - cache
- Recalcule?
  - safe
  - unsafe

</div>

<div id="right">

Easy, just change it to:

```go
func (dm *Loader) Load(
  shopid, itemid int64,
  needModels bool,
  useSlaveAPI bool
  useUnsafeAPI bool,
) Item {...}
```

And use it like:

```go
func main() {
  dm := &Loader{}
  _ = dm.Load(123, 4567,
    true, false, false, true,
  )
}
```

<div>

<!-- slide -->

![Are your serious](https://static.wixstatic.com/media/8bb61c_5e195db166bd44688b6ab0d61e39e15f~mv2.jpg)

Notes: ask audience if they want to skip next example

<!-- slide -->

## Example: logger

It starts simple

```go
type Logger interface {
  Printf(msg string, args... interface{})
}

func New(io.Writer) *Logger {...}
```

Its usage is simple:

```go
func main() {
  lg := logger.New(os.Stdout)
  lg.Printf("hello")
  // output: main.go:3 | hello
}
```

<!-- slide -->

Then, new features:

- prefix
- log level

```go
type Logger interface {
  Printf(msg string, args... interface{})
  Debuf(msg string, args... interface{})
  Errorf(msg string, args... interface{})
}

func New(
  out io.Writer,
  prefix string,
  level int,
) *Logger {...}
```

<!-- slide -->

Usage still quite simple, no need a config struct yet.

```go
func main() {
  lg := logger.New(os.Stdout, "IIS", logger.DEBUG)
  lg.Printf("hello")
  // output: main.go:3 | DEBUG
}
```

<!-- slide -->

<div id="left">

Then more features

- file rotation
- split file by log level
- async
- write to network
- serialization
  - protobuf
  - json
  - text
- ...

</div>

<div id="right">

Need a config structs

```go
package logger

type Config struct {
  Level    string
  LogPath        string
  Handlers []Handler
}

type Handler struct {
  AsyncConfig    AsyncConfig
  FormatConfig   FormatConfig
  RolloverConfig RolloverConfig
}

type AsyncConfig struct {...}
type FormatConfig struct {...}
type RolloverConfig struct {...}
```

</div>

<!-- slide -->

And the usage be like 😂

```go
func main() {
  handlerConfig := logger.FileHandlerConfig{
    Type:   "FileHandler",
    Levels: []string{"debug", "trace", "info", "warn", "error", "fatal", "data"},
    Sync: multilevel.LogSyncConfig{
      SyncWrite:     syncWrite,
      FlushInterval: 100,
      QueueSize:     uint32(queueSize),
    },
    File: fileFullPath,
    Message: multilevel.LogMessageConfig{
      Format:       "short",
      FieldsFormat: "text",
      MaxBytes:     10 * 1024 * 1024,
      MetaOption:   "All",
    },
    Rollover: multilevel.LogRolloverConfig{
      RolloverSize:     "1G",
      RolloverInterval: "1d",
      BackupCount:      100,
      BackupTime:       "7d",
    },
  }

  //
  // that's just the Handler!
  //
  ...
}
```

<!-- slide -->

## Ideas

- Define a config struct
- Define sensible default
- _Define a scalable interface_
- _Provide some optional functions_ help user modify the config to the state
  their need.

Notes: let do it step by step

<!-- slide -->

### Define a config struct

```go
type Option struct {
  useSlave    bool
  useUnsafe   bool
  needModels  bool
  needDeleted bool
}
```

### Define sensible default

```go
func defaultOps() *Option {
  return &Option{
    useSlave:  !globalCfg.UseCache,
    useUnsafe: false, // must be set explicitly
  }
}
```

<!-- slide -->

### Define a scalabel interface

```go
func (dm *Loader) Load(
  shopid, itemid int64,
  mods... OptionMod,
) Item {...}

// OptionMod is a function that modifies the input Option
type OptionMod func(o *Option)
```

- The `OptionMod` are optional arguments.
- We can provide more `OptionMod` as we adding more features.
- Existing code won't break because our API doesn't change.

<!-- slide -->

### Provide option functions

```go
func UseSlaveAPI(b bool) OptionMod {
  return func(o *Option) {o.useSlave = b}
}
func UseUnsafeAPI(b bool) OptionMod {
  return func(o *Option) {o.useUnsafe = b}
}
func NeedModels(b bool) OptionMod {
  return func(o *Option) {o.needModels = b}
}
func NeedDeletedItem(b bool) OptionMod {
  return func(o *Option) {o.needDeleted = b}
}
```

- Each one is short, easy to skim, clearly self-documented

<!-- slide -->

### API Usage

```go
func main() {
  dm := &Loader{}
  // defualt option
  item, := dm.Load(123, 4567)
  // use custormized config
  item, := dm.Load(123, 4567,
    NeedModels(globalCfg.LoadModels)
  )

  item, := dm.Load(123, 4567,
    UseUnsafeAPI(true), NeedModels(false),
    needDeleted(true), useSlaveAPI(false)
  )
}
```

- Clear usage intention
- Safe to refactor or reorder `OptionMod`

<!-- slide -->

### Downsides

- More functions to defines
- Naming those functions might be hard.
- Usage code is more verbose

<!-- slide -->

## Applications

Open source

- sqlboiler: a Go ORM generator

Shopee Internal

- `ItemInfoClient.go` in Core Server
- `sps.NewAgent()` in sps lib.
- `spkit.Client()` and `spkit.Server()`

<!-- slide -->

### sqlboiler

Example from their readme.

```go
// Query all users
users, err := models.Users().All(ctx, db)

// complex query
users, err := models.Users(
  Where("age > ?", 30),
  Limit(5),
  Offset(6),
).All(ctx, db)
```

<!-- slide -->

### sps

```go
func NewAgent(opts ...InitOption) (ag Agent, err error) {...}
// usage
sps.NewAgent(
  sps.WithInstanceID(iid),
  sps.WithConfigKey(cfg.ConfigKey),
)

// Init global agent
func Init(opts ...InitOption) error {...}
// Usage
_ = sps.Init(
  sps.WithInstanceID(iid),
  sps.WithConfigKey(configKey),
)
```

Btw, that lib has a function that drive me crazy

```go
_, _ := sps.GenerateInstanceID(
  "item.info", "", "", "", "", ""
)
```

_Which of the 4 strings to put "test" as env name?_

<!-- slide -->

### spkit

```go
// Client creates a cobra Command for the API client.
func Client(
  pcs []*sps.ProcessorConfig,
  configKey string,
  ops ...MetaModFn,
) *cobra.Command {...}

// usage
_ := spkit.Client(
  processor.AllProcessorConfigs(),
  config.DefaultSpConfigKey,
  // built-in option functions
  spkit.WithListCmd(getListSources()...),
  spkit.WithLogger(config.Logger())
  // user declared option function
  func(m *util.ServiceMetadata) {m.Version = config.Version()},
)
```

<!-- slide -->

## Q&A

<!-- slide -->

## References

- [Self-referential functions and the design of options](https://commandcenter.blogspot.com/2014/01/self-referential-functions-and-design.html)
  by Rob Pike, 2014/01
- [Functional options for friendly APIs](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis)
  by Dave Cheney, 2014/10
- [Visitor pattern](https://en.wikipedia.org/wiki/Visitor_pattern) by Gang of four, 1994
- [Go patterns](https://github.com/tmrts/go-patterns)

<!-- slide -->

## Thanks
