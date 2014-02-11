module FormatHelper

  def collection?( document )
    has_type?("collection", document)
  end

  def audio?( document )
    has_type?("sound", document)
  end

  def image?( document )
    has_type?("image", document)
  end

  def video?( document )
    has_type?("movingimage", document)
  end

  def document?( document )
    has_type?("text", document)
  end

  def has_type?( type, document )
    type.casecmp(format?( document )) == 0 ? true : false
  end

  def format? ( document )
    object = ActiveFedora::Base.find(document.id, {:cast => true})

    format = "unknown"
 
    if object.is_collection?  
      format = "collection"
    elsif !object.generic_files.empty?
       
      file = object.generic_files.first

       if file.pdf?
         format = "text"
       elsif file.audio?
         format = "sound"
       elsif file.video?
         format = "movingimage"
       elsif file.image?
         format = "image"
       end

    end

    format
  end

end
