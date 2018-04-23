class ListGenerationJob < ActiveJob::Base
  include ::MailchimpErrorHandler

  queue_as :default

  def perform(list_name, users_data, list_class_name, entity_data = {})
    gibbon_service = GibbonService::ListService.new
    list_data = gibbon_service.generate_list(list_name)
    list = list_class_name.constantize.create({ uid: list_data['id'], name: list_data['name'] }.merge(entity_data))
    if users_data.present?
      begin
        contacts_data = gibbon_service.subscribe_members(users_data.keys)
      rescue
        users_data.each{ |user| gibbon_service.subscribe_members([user.first]) rescue next }
        contacts_data = gibbon_service.members
      end
      if contacts_data.present?
        list.populate(contacts_data, users_data)
      end
    end
  end

end
