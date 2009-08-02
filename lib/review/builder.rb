#
# $Id: builder.rb 4268 2009-05-27 04:17:08Z kmuto $
#
# Copyright (c) 2002-2009 Minero Aoki
#
# This program is free software.
# You can distribute or modify this program under the terms of
# the GNU LGPL, Lesser General Public License version 2.1.
#

require 'review/index'
require 'review/exception'
require 'stringio'

module ReVIEW

  class Builder

    def initialize(strict = false, *args)
      @strict = strict
      builder_init(*args)
    end

    def builder_init(*args)
    end
    private :builder_init

    def bind(compiler, chapter, location)
      @compiler = compiler
      @chapter = chapter
      @location = location
      @output = StringIO.new
      @book = ReVIEW.book
      builder_init_file
    end

    def builder_init_file
    end
    private :builder_init_file

    def result
      @output.string
    end

    def print(*s)
      @output.print(*s)
    end

    def puts(*s)
      @output.puts(*s)
    end

    def list(lines, id, caption)
      begin
        list_header id, caption
      rescue IndexError
        error "no such list: #{id}"
      end
      list_body lines
    end

    def listnum(lines, id, caption)
      begin
        list_header id, caption
      rescue IndexError
        error "no such list: #{id}"
      end
      listnum_body lines
    end

    def source(lines, caption)
      source_header caption
      source_body lines
    end

    def image(lines, id, caption_or_metric, caption = nil)
      if caption
        metric = caption_or_metric
      else
        metric = nil
        caption = caption_or_metric
      end
      if @chapter.image(id).bound?
        image_image id, metric, caption
      else
        warn "image not bound: #{id}"
        image_dummy id, caption, lines
      end
    end

    def table(lines, id = nil, caption = nil)
      rows = []
      sepidx = nil
      lines.each_with_index do |line, idx|
        if /\A[\=\-]{12}/ =~ line
          # just ignore
          #error "too many table separator" if sepidx
          sepidx ||= idx
          next
        end
        rows.push line.strip.split(/\t+/).map {|s| s.sub(/\A\./, '') }
      end
      rows = adjust_n_cols(rows)

      begin
        table_header id, caption unless caption.nil?
      rescue IndexError => err
        error "no such table: #{id}"
      end
      return if rows.empty?
      table_begin rows.first.size
      if sepidx
        sepidx.times do
          tr rows.shift.map {|s| th(compile_inline(s)) }
        end
        rows.each do |cols|
          tr cols.map {|s| td(compile_inline(s)) }
        end
      else
        rows.each do |cols|
          h, *cs = *cols
          tr [th(compile_inline(h))] + cs.map {|s| td(compile_inline(s)) }
        end
      end
      table_end
    end

    def adjust_n_cols(rows)
      rows.each do |cols|
        while cols.last and cols.last.strip.empty?
          cols.pop
        end
      end
      n_maxcols = rows.map {|cols| cols.size }.max
      rows.each do |cols|
        cols.concat [''] * (n_maxcols - cols.size)
      end
      rows
    end
    private :adjust_n_cols

    #def footnote(id, str)
    #  @footnotes.push [id, str]
    #end
    #
    #def flush_footnote
    #  footnote_begin
    #  @footnotes.each do |id, str|
    #    footnote_item(id, str)
    #  end
    #  footnote_end
    #end

    def compile_inline(s)
      @compiler.text(s)
    end

    def inline_chapref(id)
      @chapter.env.chapter_index.display_string(id)
    rescue IndexError
      error "unknown chapter: #{id}"
      nofunc_text("[UnknownChapter:#{id}]")
    end

    def inline_chap(id)
      @chapter.env.chapter_index.number(id)
    rescue IndexError
      error "unknown chapter: #{id}"
      nofunc_text("[UnknownChapter:#{id}]")
    end

    def inline_title(id)
      @chapter.env.chapter_index.title(id)
    rescue IndexError
      error "unknown chapter: #{id}"
      nofunc_text("[UnknownChapter:#{id}]")
    end

    def inline_list(id)
      "リスト#{@chapter.list(id).number}"
    rescue IndexError
      error "unknown list: #{id}"
      nofunc_text("[UnknownList:#{id}]")
    end

    def inline_img(id)
      "図#{@chapter.image(id).number}"
    rescue IndexError
      error "unknown image: #{id}"
      nofunc_text("[UnknownImage:#{id}]")
    end

    def inline_table(id)
      "表#{@chapter.table(id).number}"
    rescue IndexError
      error "unknown table: #{id}"
      nofunc_text("[UnknownTable:#{id}]")
    end

    def inline_fn(id)
      @chapter.footnote(id).content
    rescue IndexError
      error "unknown footnote: #{id}"
      nofunc_text("[UnknownFootnote:#{id}]")
    end

    def inline_bou(str)
      text(str)
    end

    def inline_ruby(arg)
      base, ruby = *arg.split(',', 2)
      compile_ruby(base, ruby)
    end

    def inline_kw(arg)
      word, alt = *arg.split(',', 2)
      compile_kw(word, alt)
    end

    def text(str)
      str
    end

    def bibpaper(lines, id, caption)
      puts "<div>"
      bibpaper_header id, caption
      unless lines.empty?
        bibpaper_bibpaper id, caption, lines
      end
      puts "</div>"
    end

    def warn(msg)
      $stderr.puts "#{@location}: warning: #{msg}"
    end

    def error(msg)
      raise ApplicationError, "#{@location}: error: #{msg}"
    end

  end

end   # module ReVIEW
