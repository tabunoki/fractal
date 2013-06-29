

# = メインコントローラー
# Fractalアプリケーションのメインコントローラーです
class MainController < Ramaze::Controller
  
  map '/'
  
  engine :ERB
  set_layout 'default' => [:login, :logout, :index, :create, :thread, :config, :admin]
  set_layout 'error' => [:error_404]

  helper :user

  # データベースコネクション
  @@db = Sequel.connect('mysql://db_fractal_user:123456@127.0.0.1/db_fractal')

  before(:index, :logout, :create, :thread, :config, :admin) do
    redirect rs(:login) unless logged_in?
  end

  # ログイン
  def login
  
    @warnings = Array.new
  
    if logged_in?
      redirect_referer 
    end
    
    unless request.post?
      return
    end
    
    unless user_login(request.subset('user-name', 'plane-password'))
      @warnings.push("ユーザーID とパスワードが一致しません。")
    else
      redirect MainController.r(:index)
    end
    
  end

  # ログアウト
  def logout
    user_logout
    redirect_referer
  end
  
  # スレッド一覧
  def index

    @threads = @@db[:thread].order(:create_datetime.desc).all

  end

  # スレッド作成
  # スレッドの新規作成フォームを提供し、スレッドの新規作成処理を実装します。
  def create
    submit = request['submit']
    subject = request['subject']
    body = request['body']
    deadline = request['deadline']
    
    @errors = Array.new

    # スレッドの新規作成
    if submit && submit == 'create'
      if (subject && body && deadline) == false
        @errors.push('必須項目を入力して下さい。')
      end
      
      #if deadline = true && deadline 
      #  @errors.push('期限は日付を入力して下さい。')
      #end
      
      if @errors.length == 0
        begin
          @@db[:thread].insert(
            :subject => subject,
            :body => body,
            :deadline => deadline,
            :user_id => 1,
            :status => Code::STATUS[:new])
          
          redirect "/", :status => 303
        rescue => ex
          @errors.push(ex.message)
        end
      end
    end
  end

  # スレッド詳細
  # スレッドの詳細を表示し、スレッドへのリプライを実装します。
  def thread(id)
    @id= id

    submit = request['submit']
    body = request['body']

    @errors = Array.new
    @warnings = Array.new
    
    # リプライの追加
    if submit && submit == 'reply'
      if body.empty?
        @errors.push('リプライする時は本文を必ず入力して下さい。')
      end
      
      if @errors.length == 0
        begin
          @@db[:reply].insert(
            :body => body,
            :thread_id => id,
            :user_id => 1)

        rescue => ex
          @errors.push(ex.message)
        end
      end
    end
    
    # スレッド詳細の取得
    dataset = @@db[:thread].filter(:id => id)
    dataset.each do |row|
      @subject = row[:subject]
      @body = row[:body].gsub(/\r\n|\r|\n/, "<br />")
      @deadline = row[:deadline]
      @status = row[:status]
      @create_datetime = row[:create_datetime]
      @update_datetime = row[:update_datetime]
    end
    
    # リプライの取得
    @replys = @@db[:reply].filter(:thread_id => id).order(:id.asc).all
  end

  # 設定
  def config
    p "config"
  end

  # 管理
  def admin
    submit = request['submit']
    user_name = request['user-name']
    display_name = request['display-name']
    password = request['password']
    password_confirm = request['password-confirm']
    role = request['role']
    
    @errors = Array.new
    @infomations = Array.new
    
    # ユーザーの作成
    if submit && submit == 'create'
      if user_name.empty? || display_name.empty? || password.empty? || password_confirm.empty? || role.empty?
        @errors.push('必須項目を入力して下さい。')
      end

      if (password == password_confirm) == false
        @errors.push('パスワードが一致しません。')
      end

      if @errors.length == 0
        begin
          @@db[:user].insert(
            :user_name => user_name,
            :display_name => display_name,
            :password => Digest::SHA512.hexdigest(password),
            :role => role)
          
          @infomations.push("ユーザー user_name を作成しました。")
          
        rescue => ex
          @errors.push(ex.message)
        end
      end

    elsif submit && submit == 'activate'
      @infomations.push("ユーザー @test を有効にしました。")
    elsif submit && submit == 'deactivate'
      @infomations.push("ユーザー @test を無効にしました。")
    elsif submit && submit == 'delete'
      @infomations.push("ユーザー @test を削除しました。")
    end
    

    @users = @@db[:user].order(:id.desc).all
    @roles = Code::ROLE.values
  end
  
  
  def self.action_missing(path)
    if path == '/error_404'
      return
    end
    try_resolve('/error_404')
  end

  def error_404
    #render_file("#{Ramaze.options.views[0]}/error_404.xhtml")
  end

end

# ユーザー認証を管理します
class User

  @@db = Sequel.connect('mysql://db_fractal_user:123456@127.0.0.1/db_fractal')
  
  def self.authenticate(creds)

    password = Digest::SHA512.hexdigest(creds['plane-password'])
    
    dataset = @@db[:user].filter(:user_name => creds['user-name'])

    dataset.each do |row|
      if row[:password] == password
        return true
      end
    end

    return false
  end
end

