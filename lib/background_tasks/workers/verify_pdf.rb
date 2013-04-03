class VerifyPdf
  @queue = "verify_pdf_queue"

  def self.perform(object_id)
    puts "Verifying that the file for #{object_id} is a valid pdf file"
  end
end
