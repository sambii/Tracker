# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class MiscController < ApplicationController
  load_and_authorize_resource

  def upload_bulk_templates
    respond_to do |format|
      format.html
    end
  end

end
