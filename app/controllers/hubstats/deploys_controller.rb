require_dependency "hubstats/application_controller"

module Hubstats
  class DeploysController < Hubstats::BaseController

    def index
      # sets to include user and repo, and sorts data
      @deploys = Hubstats::Deploy.includes(:repo, :pull_requests, :user)
        .belonging_to_users(params[:users]).belonging_to_repos(params[:repos])
        .group_by(params[:group])
        .order_with_timespan(@timespan, params[:order])
        .paginate(:page => params[:page], :per_page => 15)

      grouping(params[:group], @deploys)
    end

    # show basic stats and pull requests from a single deploy
    def show
      @deploy = Hubstats::Deploy.includes(:repo, :pull_requests).find(params[:id])
      repo = @deploy.repo
      @pull_requests = @deploy.pull_requests
      pull_request_count = @pull_requests.length
      @stats_basics = {
        pull_count: pull_request_count,
        net_additions: @deploy.find_net_additions(@deploy),
        comment_count: @deploy.find_comment_count(@deploy),
        additions: @deploy.total_changes(@deploy, "additions"),
        deletions: @deploy.total_changes(@deploy, "deletions")
      }
    end

    # make a new deploy with all of the correct attributes
    def create
      if params[:git_revision].nil? || params[:repo_name].nil? || params[:pull_request_ids].nil?
        render text: "Missing a necessary parameter: git revision, pull request ids, or repository name.", :status => 400 and return
      else
        @deploy = Deploy.new
        @deploy.deployed_at = params[:deployed_at]
        @deploy.git_revision = params[:git_revision]
        @repo = Hubstats::Repo.where(full_name: params[:repo_name])
        if !valid_repo(@repo)
          render text: "Repository name is invalid.", :status => 400 and return
        end

        @pull_request_id_array = params[:pull_request_ids].split(",").map {|i| i.strip.to_i}
        if !valid_pr_ids
          render text: "No pull request ids given.", :status => 400 and return
        end

        if !valid_pulls
          render text: "Pull requests not valid", :status => 400 and return
        end

        if @deploy.save
          render :nothing => true, :status => 200 and return
        else
          render :nothing => true, :status => 400 and return
        end
      end
    end

    def valid_repo(repo)
      if !repo.empty?
        @deploy.repo_id = repo.first.id.to_i
        return true
      end
      return false
    end

    def valid_pr_ids
      if !@pull_request_id_array.empty? && @pull_request_id_array != [0]
        @deploy.pull_requests = Hubstats::PullRequest.where(repo_id: @deploy.repo_id).where(number: @pull_request_id_array)
        return true
      end
      return false
    end

    def valid_pulls
      if !@deploy.pull_requests.first.nil?
        if @deploy.pull_requests.first.merged_by
          @deploy.user_id = @deploy.pull_requests.first.merged_by
          return true
        end
        return false
      end
      return false
    end
  end
 end
