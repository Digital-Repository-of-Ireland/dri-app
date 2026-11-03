# frozen_string_literal: true
module DRIBatchIngest
  module IngestHelper
    BADGE_CLASSES = {
      'COMPLETED' => 'text-bg-success', 'FAILED' => 'text-bg-danger',
      'PENDING' => 'text-bg-info', 'NOT STARTED' => 'text-bg-secondary'
    }.freeze

    def status_badge(label)
      tag.span(label.capitalize, class: "badge #{BADGE_CLASSES.fetch(label, 'text-bg-secondary')}")
    end

    def batch_state(batch, counts)
      return ['Awaiting review', 'text-bg-warning'] unless batch.confirmed?
      return ['Completed', 'text-bg-success'] if counts[:total].positive? && counts[:completed] == counts[:total]
      return ['Has failures', 'text-bg-danger'] if counts[:failed].positive?

      ['In progress', 'text-bg-info']
    end

    def ingest_time(time)
      time.respond_to?(:strftime) ? time.strftime('%-d %b %Y %H:%M') : '-'
    end

    def count_links(batch, counts)
      links = { 'completed' => 'COMPLETED', 'pending' => 'PENDING', 'failed' => 'FAILED' }.filter_map do |key, status|
        count = counts[key.to_sym]
        link_to("#{count} #{key}", batch_path(batch, status: status)) if count.positive?
      end
      safe_join(links, ' · ')
    end
  end
end