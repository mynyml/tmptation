require 'pathname'
require 'tempfile'
require 'tmpdir'
require 'fileutils'

module Tmptation
  VERSION = 1.1

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

    # Delete `#path` or `#to_s` if it exists, and only if it lives within
    # `Dir.tmpdir`. If the path is a directory, it is deleted recursively.
    #
    # @raises SafeDeletable::UnsafeDelete if directory isn't within `Dir.tmpdir`
    #
    def safe_delete
      path = self.respond_to?(:path) ? self.path : self.to_s
      path = Pathname(path).expand_path

      unless path.to_s.match(/^#{Regexp.escape(Dir.tmpdir)}/)
        raise UnsafeDelete.new("refusing to remove non-tmp directory '#{path}'")
      end
      FileUtils.remove_entry_secure(path.to_s)
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

  # Subclass of core lib's Pathname that allows safely deleting all of its
  # instances.
  #
  # @example
  #
  #     path = TmpDir.new
  #     path.exist?  #=> true
  #
  #     TmpDir.delete_all
  #     path.exist?  #=> false
  #
  class TmpDir < Pathname
    include SafeDeletable
    include InstanceTracking

    class << self

      # Safe deletes and closes all instances
      def delete_all
        instances.each {|instance| instance.safe_delete }
      end
      alias -@ delete_all
    end

    # @param prefix<String> optional
    #   prefix of directory name
    #
    def initialize(prefix='TmpDir-')
      super(Pathname(Dir.mktmpdir(prefix)).expand_path)
    end
  end
end

