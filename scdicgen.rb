#!/usr/bin/env ruby
# coding: utf-8

# Copyright 2019 ffxiun0
# https://opensource.org/licenses/MIT

require 'optparse'

def main()
  options = get_options(ARGV)

  wslist = read_ws(ARGV)

  alt_write_to(options[:outfile]) {|fstream|
    options[:generate].each {|name|
      dicgen = DictionaryGenerator.create(name, wslist)
      dicgen.write(fstream)
    }
  }
end

def get_options(argv)
  options = { :generate => ["list","element","chain","loop"] }

  parser = OptionParser.new
  parser.on("-g", "--generate TARGET,TARGET,...", Array)
  parser.on("-o", "--outfile FILE")
  parser.parse!(argv, into: options)

  return options
end

def alt_write_to(file, &block)
  if file.nil? then
    block.call(STDOUT)
  else
    File.open(file, 'w') {|f|
      begin
        block.call(f)
      rescue
        File.unlink(file)
        raise
      end
    }
  end
end

def alt_read_from(files, &block)
  if files.nil? or files.empty? then
    block.call(STDIN)
  else
    files.each {|file|
      File.open(file) {|f| block.call(f) }
    }
  end
end

def read_ws(files)
  wslist = []

  alt_read_from(files) {|f|
    f.each_line {|line|
      wslist << WeaponSkill.parse(line)
    }
  }

  return wslist
end

class DictionaryGenerator
  def self.create(name, wslist)
    case name
    when "list"
      SkillListGenerator.new(wslist)
    when "element"
      ElementSkillCombinationGenerator.new(wslist)
    when "chain"
      SkillCombinationGenerator.new(wslist)
    when "nochain"
      NoChainSkillCombinationGenerator.new(wslist)
    when "loop"
      LoopChainGenerator.new(wslist)
    else
      fail("unknown generator name '" + name + "'")
    end
  end

  def write_entry(fstream, kanas, word)
    kanas.each {|kana|
      fstream.printf("%s\t%s\t短縮よみ\n", kana, word)
    }
  end
end

class SkillListGenerator < DictionaryGenerator
  def initialize(wslist)
    @wslist = wslist
  end

  def write(fstream)
    @wslist.each {|ws|
      kanas = ws.all_kanas
      word = make_word(ws)
      write_entry(fstream, kanas, word)
    }
  end

  def make_word(ws)
    list = [ws.type]
    list << ws.kind if not ws.kind.empty?
    list << ws.jobs_s if not ws.jobs_s.empty?
    desc = list.join("/")

    sprintf("%s(%s)【%s】", ws.name, ws.elems_s, desc)
  end
end

class ElementSkillCombinationGenerator < DictionaryGenerator
  def initialize(wslist)
    @wslist = wslist
  end

  def write(fstream)
    @wslist.each {|ws|
      ChainElement.all.each {|elem|
        if chain = ws.chain_from(elem) then
          kanas = make_kanas(elem, ws, chain)
          word = make_word(ws, chain)
          write_entry(fstream, kanas, word)
        end
      }
    }
  end

  def make_kanas(elem, ws, chain)
    result = []

    ws.type_kanas.each {|ws_type_kana|
      result << elem.kana + "＞" + ws_type_kana
      result << elem.kana + "＞" + ws_type_kana + "＞" + chain.chain.kana
    }
    ws.name_kanas.each {|ws_name_kana|
      result << elem.kana + "＞" + ws_name_kana
    }

    return result
  end

  def make_word(ws, chain)
    sprintf("(%s)＞%s(%s)＞[%s]%s",
            chain.first.name, ws.name, chain.second.name,
            chain.chain.name, chain.chain.last ? "<終>" : "")

  end
end

class SkillCombinationGenerator < DictionaryGenerator
  def initialize(wslist)
    @wslist = wslist
  end

  def write(fstream)
    @wslist.each {|ws1|
      @wslist.each {|ws2|
        if chain = ws1.chain(ws2) then
          kanas = make_kanas(ws1, ws2, chain)
          word = make_word(ws1, ws2, chain)
          write_entry(fstream, kanas, word)
        end
      }
    }
  end

  def make_kanas(ws1, ws2, chain)
    result = []

    ws1.name_kanas.each {|ws1_name_kana|
      ws2.name_kanas.each {|ws2_name_kana|
        result << ws1_name_kana + "＞" + ws2_name_kana
      }
    }
    ws1.name_kanas.each {|ws1_name_kana|
      ws2.type_kanas.each {|ws2_type_kana|
        result << ws1_name_kana + "＞" + ws2_type_kana
        result << ws1_name_kana + "＞" + ws2_type_kana + "＞" + chain.chain.kana
      }
    }
    ws1.type_kanas.each {|ws1_type_kana|
      ws2.name_kanas.each {|ws2_name_kana|
        result << ws1_type_kana + "＞" + ws2_name_kana
        result << ws1_type_kana + "＞" + ws2_name_kana + "＞" + chain.chain.kana
      }
    }
    ws1.type_kanas.each {|ws1_type_kana|
      ws2.type_kanas.each {|ws2_type_kana|
        result << ws1_type_kana + "＞" + ws2_type_kana
        result << ws1_type_kana + "＞" + ws2_type_kana + "＞" + chain.chain.kana
      }
    }

    return result
  end

  def make_word(ws1, ws2, chain)
    sprintf("%s(%s)＞%s(%s)＞[%s]%s",
            ws1.name, chain.first.name,
            ws2.name, chain.second.name,
            chain.chain.name, chain.chain.last ? "<終>" : "")
  end
end

class NoChainSkillCombinationGenerator < DictionaryGenerator
  def initialize(wslist)
    @wslist = wslist
  end

  def write(fstream)
    @wslist.each {|ws1|
      @wslist.each {|ws2|
        if !ws1.chain(ws2) && !ws2.chain(ws1) then
          kanas = make_kanas(ws1, ws2)
          word = make_word(ws1, ws2)
          write_entry(fstream, kanas, word)
        end
      }
    }
  end

  def make_kanas(ws1, ws2)
    result = []

    ws1.all_kanas.each {|ws1_kana|
      ws2.all_kanas.each {|ws2_kana|
        result << ws1_kana + "｜" + ws2_kana
      }
    }

    return result
  end

  def make_word(ws1, ws2)
    selfchain1 = ws1.chain(ws1) ? "<自己連携有>" : ""
    selfchain2 = ws2.chain(ws2) ? "<自己連携有>" : ""

    return sprintf("【連携しない】%s(%s)%s｜%s(%s)%s",
                   ws1.name, ws1.elems_s, selfchain1,
                   ws2.name, ws2.elems_s, selfchain2)
  end
end

class LoopChainGenerator < DictionaryGenerator
  def initialize(wslist)
    @wslist = wslist
  end

  def write(fstream)
    @wslist.each {|ws|
      next if not chain1 = ws.chain(ws)
      next if not chain2 = ws.chain_from(chain1.chain)
      next if chain1.first.name != chain2.chain.name

      kanas = ["むげんれんけい"]
      word = sprintf("【無限連携】%s(%s⇔%s)", ws.name,
                     chain1.first.name, chain1.chain.name)
      write_entry(fstream, kanas, word)
    }
  end
end

class WeaponSkill
  def initialize(type_kanas, type, name_kanas, name, elems, kind, jobs)
    (@type_kanas, @type, @name_kanas, @name, @elems, @kind, @jobs) =
      type_kanas, type, name_kanas, name, elems, kind, jobs

    @name += "(A)" if @kind == "イオニック"
  end

  def self.parse(line)
    (type_kanas, type, name_kanas, name, elems, kind, jobs) =
      line.split(/\t/).map {|s| s.strip}

    type_kanas = type_kanas.split(/\//)
    name_kanas = name_kanas.split(/\//)
    elems = ChainElement.parse(elems)
    kind = kind ? kind : ""
    jobs = jobs ? jobs.split(/\//) : []

    return WeaponSkill.new(type_kanas, type, name_kanas, name, elems, kind, jobs)
  end

  def all_kanas() @type_kanas + @name_kanas end
  def type_kanas() @type_kanas end
  def type() @type end
  def name_kanas() @name_kanas end
  def name() @name end
  def elems() @elems end
  def elems_s() @elems.empty? ? "なし" : @elems.join("/") end
  def kind() @kind end
  def jobs() @jobs end
  def jobs_s() @jobs.join("") end
  def to_s() @name end

  def chain(ws)
    @elems.each {|elem1|
      ws.elems.each{|elem2|
        if chain = elem1.chain(elem2) then
          return ChainResult.new(elem1, elem2, chain)
        end
      }
    }
    return nil
  end

  def chain_from(elem)
    @elems.each{|elem2|
      if chain = elem.chain(elem2) then
        return ChainResult.new(elem, elem2, chain)
      end
    }
    return nil
  end
end

class ChainElement
  def initialize(name, last = false)
    @name = name
    @kana = @@kana[@name]
    @last = last
  end

  def name() @name end
  def kana() @kana end
  def last() @last end
  def to_s() @name end

  def chain(elem)
    return nil if @last
    return nil if not map = @@map[@name]
    return nil if not chain = map[elem.name]
    return ChainElement.new(chain[:element], chain[:last])
  end

  def self.parse(text)
    return [] if text.nil?
    return text.split(/\//).map {|s| ChainElement.new(s.strip)}
  end

  def self.all() @@all end

  @@map = {
    "貫通" => {
      "収縮" => { element: "収縮", last: false },
      "切断" => { element: "湾曲", last: false },
      "振動" => { element: "振動", last: false }
    },
    "収縮" => {
      "貫通" => { element: "貫通", last: false },
      "炸裂" => { element: "炸裂", last: false }
    },
    "溶解" => {
      "切断" => { element: "切断", last: false },
      "衝撃" => { element: "核熱", last: false }
    },
    "切断" => {
      "溶解" => { element: "溶解", last: false },
      "振動" => { element: "振動", last: false },
      "炸裂" => { element: "炸裂", last: false }
    },
    "振動" => {
      "硬化" => { element: "硬化", last: false },
      "衝撃" => { element: "衝撃", last: false }
    },
    "炸裂" => {
      "収縮" => { element: "重力", last: false },
      "切断" => { element: "切断", last: false }
    },
    "硬化" => {
      "収縮" => { element: "収縮", last: false },
      "振動" => { element: "分解", last: false },
      "衝撃" => { element: "衝撃", last: false }
    },
    "衝撃" => {
      "溶解" => { element: "溶解", last: false },
      "炸裂" => { element: "炸裂", last: false }
    },
    "重力" => {
      "湾曲" => { element: "闇", last: false },
      "分解" => { element: "分解", last: false }
    },
    "湾曲" => {
      "重力" => { element: "闇", last: false },
      "核熱" => { element: "核熱", last: false }
    },
    "核熱" => {
      "重力" => { element: "重力", last: false },
      "分解" => { element: "光", last: false }
    },
    "分解" => {
      "湾曲" => { element: "湾曲", last: false },
      "核熱" => { element: "光", last: false }
    },
    "光" => {
      "光" => { element: "光", last: true },
    },
    "闇" => {
      "闇" => { element: "闇", last: true },
    },
  }

  @@kana = {
    "貫通" => "かんつう",
    "収縮" => "しゅうしゅく",
    "溶解" => "ようかい",
    "切断" => "せつだん",
    "振動" => "しんどう",
    "炸裂" => "さくれつ",
    "硬化" => "こうか",
    "衝撃" => "しょうげき",
    "重力" => "じゅうりょく",
    "湾曲" => "わんきょく",
    "核熱" => "かくねつ",
    "分解" => "ぶんかい",
    "光" => "ひかり",
    "闇" => "やみ",
  }

  @@all = @@map.keys.map {|s| ChainElement.new(s)}
end

class ChainResult
  def initialize(first, second, chain)
    @first = first
    @second = second
    @chain = chain
  end

  def first() @first end
  def second() @second end
  def chain() @chain end
end

main()
