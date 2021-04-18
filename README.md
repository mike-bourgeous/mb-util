# mb-util

Utility functions for interacting with the operating system, manipulating data,
etc.  Things that can't otherwise be categorized, or that are too small to
warrant their own project.  This is companion code to my [educational video
series about code and sound][0].

You might also be interested in [mb-sound][1], [mb-geometry][2], and [mb-math][3].

I recommend using this code only for non-critical tasks, not for making
important decisions or for mission-critical data modeling.

## Installation and usage

This project contains some useful programs of its own, or you can use it as a
Gem (with Git source) in your own projects.

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

## Examples

### Removing ANSI/Xterm terminal colors from text

```ruby
MB::Util.remove_ansi("\e[1mBold\e[0m")
# => 'Bold'
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

## Testing

Run `rspec`.

## Contributing

Pull requests welcome, though development is focused specifically on the needs
of my video series.

## License

This project is released under a 2-clause BSD license.  See the LICENSE file.

## See also

### Dependencies

TODO

### References

- [Terminal color sequences](https://en.wikipedia.org/wiki/ANSI_escape_code)


[0]: https://www.youtube.com/playlist?list=PLpRqC8LaADXnwve3e8gI239eDNRO3Nhya
[1]: https://github.com/mike-bourgeous/mb-sound
[2]: https://github.com/mike-bourgeous/mb-geometry
[3]: https://github.com/mike-bourgeous/mb-math
