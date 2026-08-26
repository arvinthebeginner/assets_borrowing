module BorrowRequestsHelper
  STATUS_BADGE_CLASSES = {
    "pending" => "bg-amber-100 text-amber-800",
    "approved" => "bg-blue-100 text-blue-800",
    "picked_up" => "bg-indigo-100 text-indigo-800",
    "returned" => "bg-green-100 text-green-800",
    "rejected" => "bg-red-100 text-red-800",
    "cancelled" => "bg-gray-200 text-gray-600"
  }.freeze

  OVERDUE_BADGE_CLASSES = "bg-red-600 text-white".freeze

  def borrow_status_badge(borrow_request)
    if borrow_request.overdue?
      label = "Terlambat"
      classes = OVERDUE_BADGE_CLASSES
    else
      label = t("borrow_request.statuses.#{borrow_request.status}")
      classes = STATUS_BADGE_CLASSES[borrow_request.status]
    end

    tag.span label, class: "inline-block rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
  end

  def borrow_date_range(borrow_request)
    "#{l borrow_request.start_on, format: :long} – #{l borrow_request.end_on, format: :long}"
  end
end
