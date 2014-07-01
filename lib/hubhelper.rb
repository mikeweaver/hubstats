module HubHelper
  def get_pull_number(comment)
    if comment[:pull_request]
      return comment[:pull_request][:number]
    elsif comment[:issue_url]
      return comment[:issue_url].split('/')[-1]
    elsif comment[:pull_request_url]
      return comment[:pull_request_url].split('/')[-1]
    else
      return nil
    end
  end

  def comment_setup(comment, repo, kind)
    comment[:repo_id] = repo.id
    comment[:pull_number] = get_pull_number(comment)
    comment[:kind] = kind
    return comment
  end

  def pull_setup(pull_request)
    pull_request[:repository] = pull_request[:base][:repo]
    return pull_request
  end
end