
# コードを管理します。
class Code

  # ステータスコードのハッシュ
  STATUS = {
    :new => '起票',
    :reply => '回答済み',
    :issue => '回答待ち',
    :close => '完了',
    :notice => '周知'
  }
  
  # ロールコードのハッシュ
  ROLE = {
    :developer => '開発',
    :customer => '顧客',
    :admin => '管理'
  }
end
