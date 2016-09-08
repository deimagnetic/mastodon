class FollowService < BaseService
  # Follow a remote user, notify remote user about the follow
  # @param [Account] source_account From which to follow
  # @param [String] uri User URI to follow in the form of username@domain
  def call(source_account, uri)
    target_account = follow_remote_account_service.(uri)

    return nil if target_account.nil?

    follow = source_account.follow!(target_account)

    if target_account.local?
      NotificationMailer.follow(target_account, source_account).deliver_later
    else
      NotificationWorker.perform_async(follow.stream_entry.id, target_account.id)
    end

    source_account.ping!(account_url(source_account, format: 'atom'), [Rails.configuration.x.hub_url])
    follow
  end

  private

  def follow_remote_account_service
    @follow_remote_account_service ||= FollowRemoteAccountService.new
  end
end
