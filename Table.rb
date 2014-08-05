module MyMacro

  require 'mongo' 
  include RBA
  include Mongo

##############Browser Dialog###############
class Browser < RBA::BrowserDialog

  
  def initialize(index)
    self.set_home( index )
    @browser_source = Server.new
    self.set_source( @browser_source )   
    self.show
  end

end

###############Browser Source##############
class Server < RBA::BrowserSource

  def initialize
  #Nothing here yet...
  end


  #Method for GET, 
  def get( url )
  
    url = url.sub( /^int:/, "" )
    if url == "job"
      return self.table("job")
	elsif url == "img"
      return self.table("img")
	elsif url == "defect"
      return self.table("defect")
    elsif url =~ /^toimg(.*)/
      zoomadd_img($1.to_i)
    end	
    return ""
  end
  
  #Method that generate tables from the hash array
  def table(type)
    htable="<html>"
	col=[]
    if type == "job"
	  htable += "<h1>Job Table</h1>"
	  col = $job_arr
    elsif type == "img"
	  htable += "<h1>Image Table</h1>"
	  col = $img_arr
    elsif type == "defect"
	  htable += "<h1>Defect Table</h1>"
	  col = $defect_arr
    end
	
    key = col[1].keys
    htable +="<br/><table border=\"1\"><tr>"

    key.each do |l|
     htable+="<th>#{l}</th>"
    end
    htable+="</tr>"
	
    col.each do |i|
      htable += "<tr>"
      key.each do |k|
        if k=="FILENAME"
          htable += "<td><a href=\"int:toimg#{i["IMGID"]}\">#{i[k]}</a></td>"
        else
          htable += "<td>#{i[k]}</td>"
        end
      end
      htable += "</tr>"
    end
	
    #htbale += "</table></html>" #will throw error if not commented
	
    return htable
   end
   
  #Method that open layout and insert image
  def zoomadd_img(id)
    img = Hash.new 
    $img_arr.each do |i|
      if i["IMGID"] == id
      img = i
      break
      end
    end

    img_center_x = img["image_x"]
    img_center_y = img["image_y"]
    img_layout = img["clipFile"]
    img_margin = 2
    pixel_size = 0.00281
    if !($opened_lay.include?(img_layout))
      $opened_lay.push(img_layout)
      $mw.load_layout(img_layout,2)
    end

    view = $mw.current_view
    view.max_hier
    #here goes image address,
    image_address = img["FILENAME"]

    $image = RBA::Image::new(image_address)

    @image_temp=$image.transformed(RBA::DCplxTrans::new(pixel_size, 0, false, img_center_x, img_center_y))

    view.insert_image(@image_temp)
    #here define zoom-in view
    zoom_box = RBA::DBox::new_lbrt( img_center_x-img_margin, img_center_y-img_margin, img_center_x+img_margin, img_center_y+img_margin )

    view.zoom_box(zoom_box)

  end
  
end



############################################
app = Application.instance
  $mw = app.main_window

  lv = $mw.current_view
  
  # if lv == nil
    # raise "Shape Statistics: No view selected"
  # end


client = MongoClient.new
db = client.db("mydb")
img_coll =  db.collection("img2")
job_coll =  db.collection("job")
defect_col= db.collection("defect")
$img_arr=img_coll.find({},{:fields=>{"_id"=>0,"image_x"=>1,"image_y"=>1,"IMGID"=>1,"DOE"=>1, "FILENAME"=>1,"clipFile"=>1}}).to_a #{"DOE"=>"tripleline"}
$job_arr=job_coll.find().limit(50).to_a
$defect_arr=defect_col.find().limit(50).to_a

#$job_broweser=Browser.new("int:job")
$img_browser=Browser.new("int:img")
#$defect_browser=Browser.new("int:defect")

$opened_lay=[] #names of layout that already opened

end

  
