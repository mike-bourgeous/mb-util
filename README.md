# mb-util

[![Tests](https://github.com/mike-bourgeous/mb-util/actions/workflows/test.yml/badge.svg)](https://github.com/mike-bourgeous/mb-util/actions/workflows/test.yml)

Utility functions for interacting with the operating system, manipulating data,
etc.  These are things that can't otherwise be categorized, or that are too
small to warrant their own project.  This is companion code to my [educational
video series about code and sound][0].

You might also be interested in [mb-sound][1], [mb-geometry][2], and [mb-math][3].

I recommend using this code only for non-critical tasks.

## Examples

After following the [standalone installation
instructions](#installation-and-usage), run `bin/console`.  Pry's `ls` and
`show-source -d` commands are useful for exploring.

### Removing ANSI/Xterm terminal colors from text

```ruby
MB::Util.remove_ansi("\e[1mBold\e[0m")
# => 'Bold'
```

Or, as a console script:

```bash
ls --color=force | bin/remove_ansi
```

### Pretty-printing (if the Pry gem is present)

```ruby
txt = MB::Util.highlight({a: 1, b: 2, c: 3}, columns: 10)
# => "{\e[33m:a\e[0m=>\e[1;34m1\e[0m, \e[33m:b\e[0m=>\e[1;34m2\e[0m, \e[33m:c\e[0m=>\e[1;34m3\e[0m}\n"
puts txt
# [prints colorized]
#{:a=>1,
# :b=>2,
# :c=>3}
```

### Syntax highlighting (if the CodeRay gem is present)

```ruby
txt = MB::Util.syntax("def x; {a: 1}; end")
# => "\e[32mdef\e[0m \e[1;34mx\e[0m; {\e[35ma\e[0m: \e[1;34m1\e[0m}; \e[32mend\e[0m"
puts txt
# [prints colorized]
# def x; {a: 1}; end
```

### Tabular data layout

```ruby
data = {
  a: [1, 2, 3],
  b: [4, 5, 6],
}
MB::U.table(data)
```

The data is printed to the terminal (but with colors not visible here):


```
 a | b
---+---
 1 | 4
 2 | 5
 3 | 6
```

You can use Unicode box-drawing characters instead if you like (see the method
documentation for all the options):

```ruby
MB::U.table(data, unicode: true)
```

```
 a │ b
───┼───
 1 │ 4
 2 │ 5
 3 │ 6
```

### Debugging a running process

Sometimes you want to know what an application is doing without interrupting
it.  This might even be a production web app running on a remote server where
options for debugging are limited.  You can use `sigquit_backtrace` to install
a signal handler that will print a trace for all threads if you send SIGQUIT to
your application.

In your application:

```ruby
# In your app's startup
MB::U.sigquit_backtrace

# Note: the output is a little more useful if you give your threads names
Thread.current.name = 'Main thread'
```

To generate a trace:

```bash
# From a terminal
kill -QUIT [your_app_pid]

# Or, press Ctrl-\ in the terminal where your app is running
```

And see the output (note that the output has colors not visible here):

```
Thread #<Thread:0x0000559e391bed88 run> (current thread)
========================================================
~/devel/mb-util/lib/mb/util/debug_methods.rb:23:in `backtrace'
~/devel/mb-util/lib/mb/util/debug_methods.rb:23:in `block (2 levels) in sigquit_backtrace'
~/devel/mb-util/lib/mb/util/debug_methods.rb:21:in `each'
~/devel/mb-util/lib/mb/util/debug_methods.rb:21:in `block in sigquit_backtrace'
~/.rvm/gems/ruby-2.7.8@mb-util/gems/pry-0.14.1/lib/pry/repl.rb:198:in `readline'
~/.rvm/gems/ruby-2.7.8@mb-util/gems/pry-0.14.1/lib/pry/repl.rb:198:in `block in input_readline'
.
.
.
```

## Installation and usage

This project can be experimented with by cloning the Git repo, or you can use
it as a Gem (with Git source) in your own projects.

### Standalone usage and development

First, install a Ruby version manager like RVM.  Using the system's Ruby is not
recommended -- that is only for applications that come with the system.  You
should follow the instructions from https://rvm.io, but here are the basics:

```bash
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable
```

Next, install Ruby.  RVM binary rubies are still broken on Ubuntu 20.04.x, so
use the `--disable-binary` option if you are running Ubuntu 20.04.x.

```bash
rvm install --disable-binary 2.7.3
```

You can tell RVM to isolate all your projects and switch Ruby versions
automatically by creating `.ruby-version` and `.ruby-gemset` files (already
present in this project):

```bash
cd mb-util
cat .ruby-gemset
cat .ruby-version
```

Now install dependencies:

```bash
bundle install
```

### Using the project as a Gem

To use mb-util in your own Ruby projects, add this Git repo to your
`Gemfile`:

```ruby
# your-project/Gemfile
gem 'mb-util', git: 'https://github.com/mike-bourgeous/mb-util.git
```

The utility functions will make use of the `coderay`, `pry`, and `word_wrap`
Gems if they are available in your project, but these are optional:

```ruby
gem 'pry'
gem 'coderay'
gem 'word_wrap'
```

## Testing

Run `rspec`.

## Contributing

Pull requests welcome, though development is focused specifically on the needs
of my video series.

## License

This project is released under a 2-clause BSD license.  See the LICENSE file.

## See also

### Dependencies

- [Pry](https://pry.github.io/) (optional)
- [CodeRay](http://coderay.rubychan.de/) (optional)
- [WordWrap](https://github.com/pazdera/word_wrap) (optional)

### References

- [Terminal color sequences](https://en.wikipedia.org/wiki/ANSI_escape_code)


[0]: https://www.youtube.com/playlist?list=PLpRqC8LaADXnwve3e8gI239eDNRO3Nhya
[1]: https://github.com/mike-bourgeous/mb-sound
[2]: https://github.com/mike-bourgeous/mb-geometry
[3]: https://github.com/mike-bourgeous/mb-math
