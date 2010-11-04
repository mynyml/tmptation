Summary
-------
Tmptation provides classes that help safely manipulate temporary files and
directories. Especially useful for use in tests.

Features
--------
* garbage collection of all created tmp files and dirs
* safe deletion - will refuse to delete non-tmp paths (where tmp within `Dir.tmpdir`)

Examples
--------

    # TmpFile is a subclass of Tempfile, with a few additions

    file = TmpFile.new('name', 'contents')

    file.path.exist?  #=> true
    file.closed?      #=> false
    file.read         #=> "contents"

    TmpFile.delete_all

    file.path.exist?  #=> false
    file.closed?      #=> true


    # TmpDir is a subclass of Pathname, with a few additions

    path = TmpDir.new
    path.exist?  #=> true

    TmpDir.delete_all
    path.exist?  #=> false

Mixins
------

Tmptation also contains two mixins, `SafeDeletable` and `SubclassTracking`.
They might be useful on their own. See the inline docs for more details.

Protip
------

If you use Tmptation in specs, add `TmpFile.delete_all` and `TmpDir.delete_all`
to your global teardown method:

    module MiniTest
      class Unit
        class TestCase
          def teardown
            TmpFile.delete_all
            TmpDir.delete_all
          end
        end
      end
    end

