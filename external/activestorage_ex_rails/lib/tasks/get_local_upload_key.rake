desc 'Gets the ActiveStorage key of a locally uploaded file'

task get_local_upload_key: :environment do 
  print ActiveStorage::Blob.last.key
end
