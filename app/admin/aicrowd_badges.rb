ActiveAdmin.register AicrowdBadge do
  permit_params :id, :name, :description, :badge_type_id, :code, :badges_event_id
  remove_filter :versions
end
