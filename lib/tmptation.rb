require 'pathname'
require 'tempfile'
require 'tmpdir'
require 'fileutils'
require 'forwardable'

module Tmptation
  VERSION = 1.4

  # Adds a #safe_delete method that will delete the object's associated path
  # (either #path or #to_s, if it exists) only if it lives within the system's
  # temporary directory (as defined by Dir.tmpdir)
  #
  # @example
  #
  #     path = Pathname.new('~/Documents')
  #     path.extend(SafeDeletable)
  #
  #     path.to_s #=> '~/Documents'
  #     path.safe_delete #=> raises UnsafeDelete
  #
  #     # however:
  #
  #     path = Pathname(Dir.mktmpdir).expand_path
  #
  #     Dir.tmpdir  #=> /var/folders/l8/l8EJIxZoHGGj+y1RvV0r6U+++TM/-Tmp-/
  #     path.to_s   #=> /var/folders/l8/l8EJIxZoHGGj+y1RvV0r6U+++TM/-Tmp-/20101103-94996-1iywsjo
  #
  #     path.exist? #=> true
  #     path.safe_delete
  #     path.exist? #=> false
  #
  module SafeDeletable
    UnsafeDelete = Class.new(RuntimeError)

    def self.path_for(obj)
      path = obj.respond_to?(:path) ? obj.path : obj.to_s
      path = Pathname(path).expand_path

      unless safe?(path)
        raise UnsafeDelete.new("refusing to remove non-tmp directory '#{path}'")
      end

      path
    end

    def self.safe?(path)
      !!path.to_s.match(/^#{Regexp.escape(Dir.tmpdir)}/)
    end

    # Delete `#path` or `#to_s` if it exists, and only if it lives within
    # `Dir.tmpdir`. If the path is a directory, it is deleted recursively.
    #
    # @raises SafeDeletable::UnsafeDelete if directory isn't within `Dir.tmpdir`
    #
    def safe_delete
      FileUtils.remove_entry_secure(SafeDeletable.path_for(self).to_s)
    rescue Errno::ENOENT
      # noop
    end

    def safe_delete_contents
      SafeDeletable.path_for(self).children.each {|entry| FileUtils.remove_entry_secure(entry) }
    end
  end

  # Keep track of a class's instances
  #
  # @example
  #
  #     class Foo
  #       include InstanceTracking
  #     end
  #
  #     a, b, c = Foo.new, Foo.new, Foo.new
  #
  #     [a,b,c] == Foo.instances #=> true
  #
  module InstanceTracking
    def self.included(base)
      base.class_eval do
        extend  ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def instances
        @instances ||= []
      end
    end

    module InstanceMethods
      def initialize(*args)
        super
        self.class.instances << self
      end
    end
  end

  # Subclass of core lib's Tempfile that allows safely deleting all of its
  # instances. It also provides a convenient way to add content to the file.
  #
  # @example
  #
  #     file = TmpFile.new('name', 'contents')
  #
  #     file.path.class   #=> Pathname
  #     file.path.exist?  #=> true
  #     file.closed?      #=> false
  #     file.read         #=> "contents"
  #
  #     TmpFile.delete_all
  #
  #     file.path.exist?  #=> false
  #     file.closed?      #=> true
  #
  class TmpFile < Tempfile
    include SafeDeletable
    include InstanceTracking

    class << self

      # Safe deletes and closes all instances
      def delete_all
        instances.each do |instance|
          instance.safe_delete
          instance.close
        end
        instances.clear
      end
      alias -@ delete_all
    end

    # @param name<String> optional
    #   prefix name of file
    #
    # @param body<String> optional
    #   contents of file
    #
    def initialize(name='anon', body='')
      super(name)
      self << body
      self.rewind
    end

    # File's path as a Pathname
    #
    # @return path<Pathname>
    #
    def path
      Pathname(super)
    end
  end

  # Temporary directory object which behaves like core lib's Pathname, and
  # allows safely deleting all of its instances.
  #
  # @example
  #
  #     path = TmpDir.new
  #     path.exist?  #=> true
  #
  #     TmpDir.delete_all
  #     path.exist?  #=> false
  #
  class TmpDir
    extend  Forwardable
    include SafeDeletable
    include InstanceTracking

    class << self

      # Safe deletes and closes all instances
      def delete_all
        instances.each {|instance| instance.safe_delete }
        instances.clear
      end
      alias -@ delete_all
    end

    # temporary directory's path as a Pathname
    #
    # @return path<Pathname>
    #
    attr_reader :path

    # @param prefix<String> optional
    #   prefix of directory name
    #
    def initialize(prefix='TmpDir-')
      super()
      @path = Pathname(Dir.mktmpdir(prefix)).expand_path
    end

    def_delegator :@path, :to_s

    # Delegate Pathname methods to #path
    #
    # Allows TmpDir to behave like Pathname without having to use inheritence
    # (which causes all sorts of issues).
    #
    def method_missing(name, *args) #:nodoc:
      if path.respond_to?(name)
        self.class.def_delegator :@path, name #method inlining
        send(name, *args)
      else
        super
      end
    end
  end
end

