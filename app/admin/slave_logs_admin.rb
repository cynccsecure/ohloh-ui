ActiveAdmin.register SlaveLog do
  remove_filter :job
  actions :index

  index do
    column :id
    column 'Created' do |slave_log|
      time_ago_in_words(slave_log.created_on)
    end
    column 'Host' do |slave_log|
      Slave.find(slave_log.slave_id).hostname
    end
    column 'Job' do |slave_log|
      span link_to slave_log.job_id, admin_job_path(slave_log.job_id)
    end
    column :message
  end

  controller do
    def scoped_collection
      if params[:repository_id]
        repository = Repository.find(params[:repository_id])
        repository.slave_logs
      elsif params[:job_id]
        SlaveLog.where(job_id: params[:job_id])
      end
    end
  end
end
