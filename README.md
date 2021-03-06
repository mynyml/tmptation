Summary
-------
Tmptation provides classes that help safely manipulate temporary files and
directories. Especially useful for use in tests.

Features
--------
* easy garbage collection of all created tmp files and dirs with `.delete_all`
* safe deletion - will refuse to delete non-tmp paths (as determined by `Dir.tmpdir`)

Examples
--------

```ruby
# TmpFile is a subclass of Tempfile, with a few additions

file = Tmptation::TmpFile.new('name', 'contents')

file.path.exist?  #=> true
file.closed?      #=> false
file.read         #=> "contents"

Tmptation::TmpFile.delete_all

file.path.exist?  #=> false
file.closed?      #=> true


# TmpDir behaves like Pathname, with a few additions

path = Tmptation::TmpDir.new
path.exist?  #=> true

Tmptation::TmpDir.delete_all
path.exist?  #=> false
```

Mixins
------

Tmptation also contains two mixins, `SafeDeletable` and `SubclassTracking`.
They might be useful on their own. See the inline docs for more details.

Protip
------

If you use Tmptation in tests, add `TmpFile.delete_all` and `TmpDir.delete_all`
to your global teardown method:

```ruby
class MiniTest::Unit::TestCase
  def teardown
    TmpFile.delete_all
    TmpDir.delete_all
  end
end
```
