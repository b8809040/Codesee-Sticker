require 'zip'

class StickerGeneratorController < ApplicationController
  def menu
    @current_counter = Sticker.count - 1
    @current_batch_counter = BatchRecord.count
  end

  def generate
    if params[:preview_html]
      self.preview_html "default",params
      return
    end

    if params[:preview_pdf]
      self.preview_pdf "default",params
      return
    end

    if params[:download_pdf]
      self.download_pdf params
      return
    end
  end

  def preview_pdf image_src, params
    @image_src = image_src
    @previewing_pdf = true
    @note = params[:note]
    if params[:supplier].to_s == "self_define"
      @template_lt = params[:template_lt]
      @template_rt = params[:template_rt]
      @template_lb = params[:template_lb]
      @template_rb = params[:template_rb]
      html = render_to_string(:template => "sticker_generator/template/self_define.html.erb",:layout => false)
      
      PDFKit.configure do |config|
        config.default_options = {
          :page_size     => 'A4',
          :margin_top    => '0.05in',
          :margin_right  => '0.1in',
          :margin_bottom => '0.05in',
          :margin_left   => '0.1in'
        }
      end
      kit = PDFKit.new(html, page_size: 'A4')
      #kit = PDFKit.new(html, page_width: '210', page_height: '297')
      pdf = kit.to_pdf
      file_name = "self_define.pdf"
    elsif params[:supplier].to_s == "blueco_40M"
      html = render_to_string(:template => "sticker_generator/template/blueco_40M.html.erb",:layout => false)
      PDFKit.configure do |config|
          config.default_options = {
              :page_size     => 'A4',
              :margin_top    => '0.05in',
              :margin_right  => '0.1in',
              :margin_bottom => '0.05in',
              :margin_left   => '0.1in'
          }
      end
      kit = PDFKit.new(html, page_size: 'A4')
      #kit = PDFKit.new(html, page_width: '210', page_height: '297')
      pdf = kit.to_pdf
      file_name = "blueco_40M.pdf"
    elsif params[:supplier].to_s == "blueco_18M"
      html = render_to_string(:template => "sticker_generator/template/blueco_18M.html.erb",:layout => false)
      PDFKit.configure do |config|
          config.default_options = {
              :page_size     => 'A4',
              :margin_top    => '0.05in',
              :margin_right  => '0.1in',
              :margin_bottom => '0.05in',
              :margin_left   => '0.1in'
          }
      end
      kit = PDFKit.new(html, page_size: 'A4')
      #kit = PDFKit.new(html, page_width: '210', page_height: '297')
      pdf = kit.to_pdf
      file_name = "blueco_18M.pdf"
    end
    
    send_data(pdf, filename: file_name)
  end

  def preview_html image_src, params
    @image_src = image_src
    @previewing_html = true
    @note = params[:note]
    if params[:supplier].to_s == "self_define"
      @template_lt = params[:template_lt]
      @template_rt = params[:template_rt]
      @template_lb = params[:template_lb]
      @template_rb = params[:template_rb]
      render "sticker_generator/template/self_define.html.erb"
    elsif params[:supplier].to_s == "blueco_40M"
      render "sticker_generator/template/blueco_40M.html.erb"
    elsif params[:supplier].to_s == "blueco_18M"
      render "sticker_generator/template/blueco_18M.html.erb"
    end
  end

  def download_pdf params
    @note = params[:note]

    copy_counter = 1
    if !params[:copy].blank?
        copy_counter = params[:copy].to_i
    end

    # Keep the sticker package information
    b = BatchRecord.new
    b.sticker_id = Sticker.count - 1# the start of sticker id of this batch
    b.note = @note

    current_batch_counter = BatchRecord.count

    logger.info "current_batch_counter=#{current_batch_counter}"

    amount = 0
    total_amount = 0
    download_files = []
    while copy_counter > 0
      if params[:supplier].to_s == "self_define"
        # calculate the needed amount of qrcode
        current_counter = Sticker.count - 1 # numbering from zero~>n, minus one required
        amount = 0
        lt_count = 0
        rt_count = 0
        lb_count = 0
        rb_count = 0

        if params[:template_lt].to_s == "classic_3x3"
          amount += 9
          lt_count = 9
        elsif params[:template_lt].to_s == "classic_2x3"
          amount += 6
          lt_count = 6
        end

        if params[:template_rt].to_s == "classic_3x3"
          amount += 9
          rt_count = lt_count + 9
        elsif params[:template_rt].to_s == "classic_2x3"
          amount += 6
          rt_count = lt_count + 6
        end

        if params[:template_lb].to_s == "classic_3x3"
          amount += 9
          lb_count = rt_count + 9
        elsif params[:template_lb].to_s == "classic_2x3"
          amount += 6
          lb_count = rt_count + 6
        end

        if params[:template_rb].to_s == "classic_3x3"
          amount += 9
          rb_count = lb_count + 9
        elsif params[:template_rb].to_s == "classic_2x3"
          amount += 6
          rb_count = lb_count + 6
        end

        # debug information
        logger.info "amount=#{amount}"
        logger.info "current_counter=#{current_counter}"
        logger.info "lt:#{lt_count} rt:#{rt_count} lb:#{lb_count} rb:#{rb_count}"

        # generate qrcode by pki
        self.generate_qrcode current_counter,amount

        # store the serials
        @template_lt_serials = []
        @template_rt_serials = []
        @template_lb_serials = []
        @template_rb_serials = []

        i=0
        IO.foreach("/home/leo/codesee/codesee/qrcode_list_#{current_counter}_#{amount}.txt") do |line|
          # process the line of text here
          s = Sticker.new
          s.serial = line.strip
          s.batch_id = b.id
          s.save

          if i < lt_count
            @template_lt_serials << s.serial
          elsif i >= lt_count && i < rt_count
            @template_rt_serials << s.serial
          elsif i >= rt_count && i < lb_count
            @template_lb_serials << s.serial
          elsif i >= lb_count && i < rb_count
            @template_rb_serials << s.serial
          end

          i=i+1
        end

        @image_src = "qrcode_list_#{current_counter}_#{amount}"

        @template_lt = params[:template_lt]
        @template_rt = params[:template_rt]
        @template_lb = params[:template_lb]
        @template_rb = params[:template_rb]
        PDFKit.configure do |config|
          config.default_options = {
            :page_size     => 'A4',
            :margin_top    => '0.05in',
            :margin_right  => '0.1in',
            :margin_bottom => '0.05in',
            :margin_left   => '0.1in'
          }
        end
        html = render_to_string(:template => "sticker_generator/template/self_define.html.erb",:layout => false)
        kit = PDFKit.new(html, page_size: 'A4')
        #kit = PDFKit.new(html, page_width: '210', page_height: '297')
        pdf_file  = kit.to_file "tmp/pdfkit/Codesee_#{current_counter}_#{amount}.pdf"
        download_files << "Codesee_#{current_counter}_#{amount}.pdf"
      elsif params[:supplier].to_s == "blueco_40M"
        # calculate the needed amount of qrcode
        current_counter = Sticker.count - 1
        amount = 40

        # debug information
        logger.info "amount=#{amount}"
        logger.info "current_counter=#{current_counter}"

        # generate qrcode by pki
        self.generate_qrcode current_counter,amount

        # store the serials
        @serials = []

        IO.foreach("/home/leo/codesee/codesee/qrcode_list_#{current_counter}_#{amount}.txt") do |line|
          # process the line of text here
          s = Sticker.new
          s.serial = line.strip
          s.batch_id = b.id
          s.save

          @serials << s.serial
        end

        @image_src = "qrcode_list_#{current_counter}_#{amount}"

        PDFKit.configure do |config|
          config.default_options = {
            :page_size     => 'A4',
            :margin_top    => '0.05in',
            :margin_right  => '0.1in',
            :margin_bottom => '0.05in',
            :margin_left   => '0.1in'
          }
        end
        html = render_to_string(:template => "sticker_generator/template/blueco_40M.html.erb",:layout => false)
        kit = PDFKit.new(html, page_size: 'A4')
        #kit = PDFKit.new(html, page_width: '210', page_height: '297')
        pdf_file  = kit.to_file "tmp/pdfkit/Codesee_#{current_counter}_#{amount}.pdf"
        download_files << "Codesee_#{current_counter}_#{amount}.pdf"
      elsif params[:supplier].to_s == "blueco_18M"
        # calculate the needed amount of qrcode
        current_counter = Sticker.count - 1
        amount = 18

        # debug information
        logger.info "amount=#{amount}"
        logger.info "current_counter=#{current_counter}"

        # generate qrcode by pki
        self.generate_qrcode current_counter,amount

        # store the serials
        @serials = []

        IO.foreach("/home/leo/codesee/codesee/qrcode_list_#{current_counter}_#{amount}.txt") do |line|
          # process the line of text here
          s = Sticker.new
          s.serial = line.strip
          s.batch_id = b.id
          s.save

          @serials << s.serial
        end

        @image_src = "qrcode_list_#{current_counter}_#{amount}"
        @current_counter = current_counter
        @amount = amount

        PDFKit.configure do |config|
          config.default_options = {
            :page_size     => 'A4',
            :margin_top    => '0.05in',
            :margin_right  => '0.1in',
            :margin_bottom => '0.05in',
            :margin_left   => '0.1in'
          }
        end
        html = render_to_string(:template => "sticker_generator/template/blueco_18M.html.erb",:layout => false)
        kit = PDFKit.new(html, page_size: 'A4')
        #kit = PDFKit.new(html, page_width: '210', page_height: '297')
        #https://stackoverflow.com/questions/7588358/rails-how-to-create-a-file-from-a-controller-and-save-it-in-the-server
        pdf_file  = kit.to_file "tmp/pdfkit/Codesee_#{current_counter}_#{amount}.pdf"
        download_files << "Codesee_#{current_counter}_#{amount}.pdf"
      end

      copy_counter = copy_counter - 1
      total_amount = total_amount + amount
    end # end while

    # Keep the sticker package information
    b.amount = total_amount
    b.save

    #https://stackoverflow.com/questions/44693925/how-to-download-multiple-files-from-s3-as-zip-format-in-rails-5-x-x-app
    folder_path = "#{Rails.root}/tmp/pdfkit"
    zipfile_name = "Codesee_#{current_batch_counter}_#{total_amount}.zip"

    Zip::File.open("#{folder_path}/#{zipfile_name}", Zip::File::CREATE) do |file|
      download_files.each do |pdf_file|
        file.add(pdf_file,File.join(folder_path,pdf_file))
      end
    end

    send_file(File.join(folder_path, zipfile_name), :type => 'application/zip', :filename => zipfile_name)

  end #end of download_pdf

  def generate_qrcode current_counter, amount
      # generate qrcode by pki
      system("cd /home/leo/codesee/codesee;./qrcode_list_creator.sh #{current_counter} #{amount};./pki_batch_encrypt.sh ./qrcode_list_#{current_counter}_#{amount};./qrcode_image_creator.sh ./qrcode_list_#{current_counter}_#{amount}")
      system("mv /home/leo/codesee/codesee/qrcode_list_#{current_counter}_#{amount} /home/leo/codesee/CodeseeSticker/app/assets/images/")
  end

end
