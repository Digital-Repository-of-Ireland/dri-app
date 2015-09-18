module Dri

# A class to represent the SDR repository store
 #
# ====Data Model
# * <b>{StorageRepository} = represents the digital object repository storage areas</b>
#
# @note Copyright (c) 2012 by The Board of Trustees of the Leland Stanford Junior University.
#   All rights reserved.  See {file:LICENSE.rdoc} for details.
class StorageRepository < Moab::StorageRepository

           def storage_branch(object_id)
             dir = ""
             index = 0

               4.times {
                 dir = File.join(dir, object_id[index..index+1])
                 index += 2
               }

               File.join(dir, object_id)
           end

           # @param object_id [String] The identifier of the digital object
           # @return [Pathname] The branch segment of the object deposit path
           def deposit_branch(object_id)
             object_id.split(/:/)[-1]
           end
     end
   
     end
