

# = メインコントローラー
# Fractalアプリケーションのメインコントローラーです
class MainController < Ramaze::Controller
  
  map '/'
  
  engine :ERB
  set_layout 'default' => [:login, :logout, :index, :create, :thread, :config, :admin, :hello]

  helper :user

  # データベースコネクション
  @@db = Sequel.connect('mysql://db_fractal_user:123456@127.0.0.1/db_fractal')

  before(:index, :logout, :create, :thread, :config, :admin) do
    redirect rs(:login) unless logged_in?
  end

  # ログイン
  def login
    redirect_referer if logged_in?
    return unless request.post?
    user_login(request.subset('user-id', 'plane-password'))
    redirect MainController.r(:index)
    
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
  # スレッドの新規作成フォームを提供し、
  # スレッドの新規作成処理を実装します。
  def create
    submit = request['submit']
    subject = request['subject']
    body = request['body']
    deadline = request['deadline']
    
    @alerts = Array.new

    # スレッドの新規作成
    if submit && submit == 'create'
      if (subject && body && deadline) == false
        @alerts.push('必須項目を入力して下さい。')
      end
      
      #if deadline = true && deadline 
      #  @alerts.push('期限は日付を入力して下さい。')
      #end
      
      if @alerts.length = 0
        begin
          @@db[:thread].insert(
            :subject => subject,
            :body => body,
            :deadline => deadline,
            :user_name => 1,
            :status => Code::STATUS[:new])
          
          redirect "/", :status => 303
        rescue => ex
          @alerts.push(ex.message)
        end
      end
    end
  end

  # スレッド詳細
  def thread(id)
    @id= id

    
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
  end

  # 設定
  def config
    p "config"
  end

  # 管理
  def admin
    submit = request['submit']
    user_id = request['user-id']
    user_name = request['user-name']
    password = request['password']
    password_confirm = request['password-confirm']
    role = request['role']
    
    @alerts = Array.new
    
    # ユーザーの作成
    if submit && submit == 'create'
      if user_id.empty? || user_name.empty? || password.empty? || password_confirm.empty? || role.empty?
        @alerts.push('必須項目を入力して下さい。')
      end

      if (password == password_confirm) == false
        @alerts.push('パスワードが一致しません。')
      end

      if @alerts.length == 0
        begin
          @@db[:user].insert(
            :user_id => user_id,
            :user_name => user_name,
            :password => Digest::SHA512.hexdigest(password),
            :role => role)
        rescue => ex
        p ex.message
          @alerts.push(ex.message)
        end
      end
    end

    @users = @@db[:user].order(:id.desc).all
    @roles = Code::ROLE.values
  end
  
  # テスト画面
  def hello(name, world)
    "Hello #{name}. Welcome to #{world} World! test"
  end


end

# ユーザー認証を管理します
class User

  @@db = Sequel.connect('mysql://db_fractal_user:123456@127.0.0.1/db_fractal')
  
  def self.authenticate(creds)

    password = Digest::SHA512.hexdigest(creds['plane-password'])
    
    dataset = @@db[:user].filter(:user_id => creds['user-id'])

    dataset.each do |row|
      if row[:password] == password
        return true
      end
    end

    return false
  end
end

