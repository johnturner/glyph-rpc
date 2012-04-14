require 'set'
require 'data'

class Encoder
  CONTENT_TYPE='application/vnd.glyph'
  UNICODE_CHARSET="utf-8"

  BSTR='b'
  UNI='u'
  END_ITEM="\x0a"

  FLT='f'
  NUM='i'
  DTM='d'

  DICT='D'
  LIST='L'
  SET='S'
  END_DICT = END_LIST = END_SET ='E'

  TRUE='T'
  FALSE='F'
  NONE='N'

  NODE='X'
  EXT='Y'

  def initialize
    @node = Node
    @extention = Extension
  end
  
  def dump obj, str='', &resolver
    if obj == true
      str << TRUE
    elsif obj == false
      str << FALSE
    elsif obj.nil?
      str << NONE
    elsif @extension === obj
      str << EXT
      name, attributes, content = obj._get_state
      obj.resolve &resolver
      dump name, str, &resolver
      dump attributes, str, &resolver
      dump content, str, &resolver
      
    elsif @node === obj
      str << NODE if @node === obj
      name, attributes, content = obj._get_state
      dump name, str, &resolver
      dump attributes, str, &resolver
      dump content, str, &resolver
    
    elsif String === obj
      #unicode only supported in ruby >1.9 only
      if obj.respond_to? :encoding and obj.encoding.name.contains "UTF" 
        str << UNI
        obj = obj.encode(UNICODE_CHARSET)
        str << obj.bytesize.to_s
        str << END_ITEM
        str << obj
      else 
        str << BSTR
        str << obj.size.to_s
        str << END_ITEM
        str << obj
      end
    
    elsif Set === obj
      str << SET
      obj.each do |item|
        dump(item, str, &resolver)
      end
      str << END_SET

    elsif Array === obj
      str << LIST
      obj.each do |item|
        dump(item, str, &resolver)
      end
      str << END_LIST

    elsif Hash === obj
      str << DICT
      obj.keys.each do |key|
        dump(key, str, &resolver)
        dump(obj[key], str, &resolver)
      end
      str << END_DICT

    elsif Integer === obj
      str << NUM
      str << obj.to_s
      str << END_ITEM

    elsif Float === obj
      str << FLT
      str << f_to_hex(obj)
      str << END_ITEM

    elsif Time === obj
      str << DTM
      str << obj.utc.strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    else
      raise Exception.new("Couldn't encode: #{obj.inspect}")
    end
  end

  #FIXME: Ew, ew, ew (ew).  Slow and probably breaks horribly for certain floats.
  def f_to_hex f
    return 'nan' if f.nan?
    if f.infinite?
      if f > 0
        return 'inf'
      else
        return '-inf'
      end
    end

    sign = ''
    integer = 0
    fraction = []
    exponent = 0

    if f < 0
      sign = '-'
      f = -f
    end

    while (f <= 1)
      f *= 2
      exponent -= 1
    end
    
    while (f >= 10)
      f /= 2
      exponent += 1
    end

    integer = f.to_i
    f -= integer
    
    while (f and fraction.size < 16)
      divisor = (16 ** (fraction.size+1)).to_f
      frac = 1
      while (f - frac/divisor > 0 and frac < 16)
        frac += 1
      end
      frac -= 1
      fraction << frac
      f -= frac/divisor
    end
    str = sign+"0x#{integer}."
    fraction.each do |frac|
      str << frac.to_s(16)
    end
    str << "p#{exponent}"
    str
  end
end
