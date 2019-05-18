require 'net/http'

10.times do
  user = User.new

  file_url = 'http://lorempixel.com/300/300/'
  remote_file = Net::HTTP.get_response(URI.parse(file_url))
  user.avatar.attach(
    io: StringIO.new(remote_file.body), 
    filename: "#{SecureRandom.hex}.jpeg", 
    content_type: 'image/jpeg'
  )

  user.save
end

10.times do
  post = Post.new

  3.times do 
    file_url = 'http://lorempixel.com/300/300/'
    remote_file = Net::HTTP.get_response(URI.parse(file_url))
    post.photos.attach(
      io: StringIO.new(remote_file.body), 
      filename: "#{SecureRandom.hex}.jpeg", 
      content_type: 'image/jpeg'
    )
  end

  post.save
end
