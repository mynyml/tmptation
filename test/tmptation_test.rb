require 'minitest/autorun'
require 'minitest/spec'
require 'rr'

begin require 'ruby-debug'; rescue LoadError; end
begin require 'redgreen'  ; rescue LoadError; end
begin require 'phocus'    ; rescue LoadError; end

class MiniTest::Unit::TestCase
  include RR::Adapters::TestUnit
end

require 'tmptation'
include  Tmptation

describe Tmptation::SafeDeletable do

  it "should delete a tmp directory" do
    begin
      dir = Pathname(Dir.mktmpdir('SafeDeletable-')).expand_path
      dir.extend(SafeDeletable)
      
      assert dir.exist?
      assert_match /^#{Regexp.quote(Dir.tmpdir)}/, dir.to_s

      dir.safe_delete

      refute dir.exist?
    ensure
      dir.rmdir if dir.directory?
    end
  end

  it "should refuse to delete a non-tmp directory" do
    begin
      dir = Pathname(ENV['HOME']).join("tmptation-tmpdir-#{Time.now.to_f}").expand_path
      dir.extend(SafeDeletable)

      refute dir.exist?
      dir.mkdir
      
      assert dir.exist?
      refute_match /^#{Regexp.quote(Dir.tmpdir)}/, dir.to_s

      assert_raises(SafeDeletable::UnsafeDelete) { dir.safe_delete }
    ensure
      dir.rmdir if dir.directory?
    end
  end

  it "should hanled relative paths" do
    begin
      dir = Pathname(Dir.mktmpdir('SafeDeletable-')).relative_path_from(Pathname(Dir.pwd))
      dir.extend(SafeDeletable)

      assert_match /^#{Regexp.quote(Dir.tmpdir)}/, dir.expand_path.to_s
      assert dir.relative?

      dir.safe_delete

      refute dir.exist?
    ensure
      dir.rmdir if dir.directory?
    end
  end

  it "should use an object's #path if it exists" do
    begin
      file = Tempfile.new('safe_deletable')
      file.extend(SafeDeletable)

      assert File.exist?(file.path)
      assert_match /^#{Regexp.quote(Dir.tmpdir)}/, file.path.to_s

      file.safe_delete

      refute File.exist?(file.path)
    ensure
      file.delete if File.exist?(file)
    end
  end
end

describe Tmptation::InstanceTracking do

  before do
    TmpFile.instance_variable_set(:@instances, nil)
  end

  it "should keep track of class instances" do
    klass = Class.new
    klass.class_eval { include InstanceTracking }

    assert_empty klass.instances

    foo, bar = klass.new, klass.new
    assert_equal [foo,bar], klass.instances
  end
end

describe Tmptation::TmpFile do

  before do
    TmpFile.instance_variable_set(:@instances, nil)
  end

  it "should implement SafeDeletable" do
    assert_includes TmpFile.included_modules, SafeDeletable
  end

  it "should implement InstanceTracking" do
    assert_includes TmpFile.included_modules, InstanceTracking
  end

  it "should create a new temporary file on init" do
    begin
      foo  = TmpFile.new

      assert File.exist?(foo.path)
      assert_match /^#{Regexp.quote(Dir.tmpdir)}/, foo.path.to_s
    ensure
      foo.delete if foo.path.exist?
    end
  end

  it "should provide a path as Pathname" do
    begin
      foo  = TmpFile.new
      assert_kind_of Pathname, foo.path
    ensure
      foo.delete if foo.path.exist?
    end
  end

  it "should allow setting a name and body on init" do
    begin
      foo  = TmpFile.new('name', 'body')

      assert_match /^name/, foo.path.basename.to_s
      assert_equal 'body',  foo.read
    ensure
      foo.delete if foo.path.exist?
    end
  end

  it "should delete all instances" do
    begin
      foo, bar = TmpFile.new, TmpFile.new
      
      assert foo.path.exist?
      assert bar.path.exist?

      TmpFile.delete_all
      
      refute foo.path.exist?
      refute bar.path.exist?
    ensure
      foo.delete if foo.path.exist?
      bar.delete if bar.path.exist?
    end
  end

  it "should use #safe_delete" do
    begin
      foo = TmpFile.new

      mock(foo).safe_delete
      TmpFile.delete_all

      RR.verify
    ensure
      foo.delete if foo.path.exist?
    end
  end

  it "should close files when deleting all instances" do
    begin
      foo = TmpFile.new
      refute foo.closed?

      TmpFile.delete_all
      assert foo.closed?
    ensure
      foo.delete if foo.path.exist?
    end
  end
end

describe Tmptation::TmpDir do

  before do
    TmpDir.instance_variable_set(:@instances, nil)
  end

  it "should implement SafeDeletable" do
    assert_includes TmpDir.included_modules, SafeDeletable
  end

  it "should implement InstanceTracking" do
    assert_includes TmpFile.included_modules, InstanceTracking
  end

  it "should create a temporary directory on init" do
    begin
      foo = TmpDir.new

      assert foo.exist?
      assert_match /^#{Regexp.quote(Dir.tmpdir)}/, foo.to_s
    ensure
      foo.rmdir if foo.exist?
    end
  end

  it "should allow setting a prefix on init" do
    begin
      foo  = TmpDir.new('prefix-')
      assert_match /^prefix/, foo.to_s.split('/').last
    ensure
      foo.rmdir if foo.exist?
    end
  end

  it "should delete all instances" do
    begin
      foo, bar = TmpDir.new, TmpDir.new
      
      assert foo.exist?
      assert bar.exist?

      TmpDir.delete_all
      
      refute foo.exist?
      refute bar.exist?
    ensure
      foo.rmdir if foo.exist?
      bar.rmdir if foo.exist?
    end
  end

  it "should use #safe_delete" do
    begin
      foo = TmpDir.new

      mock(foo).safe_delete
      TmpDir.delete_all

      RR.verify
    ensure
      foo.rmdir if foo.exist?
    end
  end
end

