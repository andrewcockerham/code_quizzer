class ExamsController < ApplicationController
  def grade_exam
    @exam = Exam.find(params[:id])
    authorize! :update, @exam
    @exam.update_attribute(:is_graded, true)
    respond_to do |format|
      methods = [:percent_correct, :correct_answers_count, :incorrect_answers_count, :blank_answers_count]
      format.json { render :json => @exam.to_json(methods: methods) }
    end
  end

  def cancel_exam
    exams = Exam.where(:quiz_id => params[:quiz_id], :user_id => current_user.id, :is_canceled => nil)
    authorize! :update, exams.first
    exams.each { |e| e.update_attribute(:is_canceled, true) }
    respond_to do |format|
      format.json { render :json => exams }
    end
  end

  def index
    @completed_exams = Exam.where(:is_graded => true).limit(50).order("updated_at desc")
    @exams_in_progress = Exam.where("is_graded IS NULL").limit(50).order("created_at desc")
  end

  def user_exams
    @completed_exams = Exam.where(:user_id => current_user.id, :is_graded => true).limit(50).order("updated_at desc")
    @exams_in_progress = Exam.where(:user_id => current_user.id).where("is_graded IS NULL").limit(50).order("created_at desc")
  end

  def send_to_SkillChest
    @completed_exams = Exam.where(:user_id => current_user.id, :is_graded => true).limit(50).order("updated_at desc")
    require "net/http"
    puts params
    # uri = URI('http://agile-everglades-3155.herokuapp.com/users/receive_certificate')
    uri = URI('http://www.skillchest.com/users/receive_certificate')
    puts uri
    puts @completed_exams.first.percent_correct ## is this the correct one to send? need to ensure that the one that is clicked is the one that is sent
    x = Net::HTTP.post_form(uri, params) ## MAKE THIS MORE SECURE
    puts x.body
    redirect_to user_exams_path, notice: 'You have sent your pdf to <u><a href=http://www.skillchest.com/fiveminutechinese>SkillChest</a></u>. Login now to check it out!'.html_safe
  end

  def graded_count
    respond_to do |format|
      if current_user
        result = Exam.status_counts(current_user.id)
        format.json { render :json => result }
      else
        format.json { head :no_content }
      end
    end
  end

end
