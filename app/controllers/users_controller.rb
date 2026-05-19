class UsersController < ApplicationController
  def show
    load_profile("feed")
  end

  def devlogs
    load_profile("devlogs")
    render :show
  end

  def replies
    load_profile("replies")
    render :show
  end

  def projects
    load_profile("projects")
    render :show
  end

  def update
    @user = User.find(params[:id])
    authorize @user

    if @user.update(user_params)
      redirect_to user_path(@user), notice: "Profile updated."
    else
      redirect_to user_path(@user), alert: @user.errors.full_messages.to_sentence
    end
  end

  def followers
    @user = User.find(params[:id])
    authorize @user
    @followers = @user.followers.order(:display_name)
    render layout: false
  end

  def following
    @user = User.find(params[:id])
    authorize @user
    @following = @user.following.order(:display_name)
    render layout: false
  end

  private

  def load_profile(active_tab)
    @user = User.includes(:preference).find(params[:id])
    authorize @user

    @body_class = "app-layout-page"
    @active_tab = active_tab

    @projects = @user.projects
                     .select(:id, :title, :description, :created_at, :updated_at, :ship_status, :shipped_at, :devlogs_count, :duration_seconds)
                     .order(created_at: :desc)
                     .includes(:users, banner_attachment: :blob)

    @activity = Post.joins(:project)
                    .merge(Project.not_deleted)
                    .where(user_id: @user.id)
                    .order(created_at: :desc)
                    .preload(:project, :user, postable: [ { attachments_attachments: :blob } ])

    unless policy(@user).view_unapproved_ship_events?
      approved_ship_event_ids = Post::ShipEvent.where(certification_status: "approved").pluck(:id)
      @activity = @activity.where("postable_type != 'Post::ShipEvent' OR postable_id IN (?)", approved_ship_event_ids.presence || [ 0 ])
    end

    unless policy(@user).view_deleted_devlogs?
      deleted_devlog_ids = Post::Devlog.unscoped.deleted.pluck(:id)
      @activity = @activity.where.not(postable_type: "Post::Devlog", postable_id: deleted_devlog_ids)
    end

    post_counts_by_type = Post.where(user_id: @user.id).group(:postable_type).count
    devlogs_count = post_counts_by_type["Post::Devlog"] || 0
    ships_count = post_counts_by_type["Post::ShipEvent"] || 0
    votes_count = @user.votes_count || Vote.where(user_id: @user.id).count

    @stats = {
      devlogs_count: devlogs_count,
      ships_count: ships_count,
      votes_count: votes_count,
      projects_count: @projects.size
    }

    @follower_count  = @user.followers.count
    @following_count = @user.following.count
    @viewer_follows  = current_user&.follows?(@user) || false
  end

  def user_params
    params.require(:user).permit(:bio, :banner)
  end
end
