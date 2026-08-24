module AssetUnitsHelper
  STATUS_BADGE_CLASSES = {
    "available" => "bg-green-100 text-green-800",
    "maintenance" => "bg-amber-100 text-amber-800",
    "retired" => "bg-gray-200 text-gray-600"
  }.freeze

  CONDITION_BADGE_CLASSES = {
    "good" => "bg-green-100 text-green-800",
    "minor_damage" => "bg-yellow-100 text-yellow-800",
    "damaged" => "bg-red-100 text-red-800",
    "lost" => "bg-gray-800 text-white"
  }.freeze

  def unit_status_badge(unit)
    badge t("asset_unit.statuses.#{unit.status}"), STATUS_BADGE_CLASSES[unit.status]
  end

  def unit_condition_badge(unit)
    badge t("asset_unit.conditions.#{unit.condition}"), CONDITION_BADGE_CLASSES[unit.condition]
  end

  private
    def badge(label, classes)
      tag.span label, class: "inline-block rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
    end
end
