module ChefSpec::Matchers
  class NotificationsMatcher
    include ChefSpec::Normalize

    def initialize(signature)
      signature.match(/^([^\[]*)\[(.*)\]$/)
      @expected_resource_type = $1
      @expected_resource_name = $2
    end

    def matches?(resource)
      @resource = resource

      if @resource
        block = Proc.new do |notified|
          resource_name(notified.resource).to_s == @expected_resource_type &&
          (@expected_resource_name === notified.resource.identity.to_s || @expected_resource_name === notified.resource.name.to_s) &&
          matches_action?(notified)
        end

        if @immediately
          immediate_notifications.any?(&block)
        elsif @delayed
          delayed_notifications.any?(&block)
        else
          all_notifications.any?(&block)
        end
      end
    end

    def to(action)
      @action = action.to_sym
      self
    end

    def immediately
      @immediately = true
      self
    end

    def delayed
      @delayed = true
      self
    end

    def description
      message = %Q{notify "#{@expected_resource_type}[#{@expected_resource_name}]"}
      message << " with action :#{@action}" if @action
      message << " immediately" if @immediately
      message << " delayed" if @delayed
      message
    end

    def failure_message_for_should
      if @resource
        message = %Q{expected "#{resource_name(@resource)}[#{@resource.name}]" to notify "#{@expected_resource_type}[#{@expected_resource_name}]"}
        message << " with action :#{@action}" if @action
        message << " immediately" if @immediately
        message << " delayed" if @delayed
        message << ", but did not."
        message << "\n\n"
        message << "Other notifications were:\n\n#{format_notifications}"
        message << "\n "
        message
      else
        message = %Q{expected _something_ to notify "#{@expected_resource_type}[#{@expected_resource_name}]"}
        message << " with action :#{@action}" if @action
        message << " immediately" if @immediately
        message << " delayed" if @delayed
        message << ", but the _something_ you gave me was nil! If you are running a test like:"
        message << "\n\n"
        message << "  expect(_something_).to notify('...')"
        message << "\n\n"
        message << "Make sure that `_something_` exists, because I got nil"
        message << "\n "
        message
      end
    end

    def failure_message_for_should_not
      if @resource
        message = %Q{did not expect "#{resource_name(@resource)}[#{@resource.name}]" to notify "#{@expected_resource_type}[#{@expected_resource_name}]"}
        message << " with action :#{@action}" if @action
        message << " immediately" if @immediately
        message << " delayed" if @delayed
        message << ", but did."
        message << "\n\n"
        message << "Other notifications were:\n\n#{format_notifications}"
        message << "\n "
        message
      else
        message = %Q{did not expect _something_ to notify "#{@expected_resource_type}[#{@expected_resource_name}]"}
        message << " with action :#{@action}" if @action
        message << " immediately" if @immediately
        message << " delayed" if @delayed
        message << ", but the _something_ you gave me was nil! If you are running a test like:"
        message << "\n\n"
        message << "  expect(_something_).to_not notify('...')"
        message << "\n\n"
        message << "Make sure that `_something_` exists, because I got nil"
        message << "\n "
        message
      end
    end

    private
      def all_notifications
        immediate_notifications + delayed_notifications
      end

      def immediate_notifications
        @resource.immediate_notifications
      end

      def delayed_notifications
        @resource.delayed_notifications
      end

      def matches_action?(notification)
        return true if @action.nil?
        @action == notification.action.to_sym
      end

      def format_notification(notification)
        notifying_resource = notification.notifying_resource
        resource = notification.resource
        type = notification.notifying_resource.immediate_notifications.include?(notification) ? :immediately : :delayed

        %Q{  "#{notifying_resource.to_s}" notifies "#{resource_name(resource)}[#{resource.name}]" to :#{notification.action}, :#{type}}
      end

      def format_notifications
        all_notifications.map do |notification|
          '  ' + format_notification(notification)
        end.join("\n")
      end
  end
end
