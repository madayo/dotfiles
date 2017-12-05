#! /bin/bash -e

# git管理下にある dotfile のみ抽出
for f in `git ls-files | sed -s 's/\/.*//g' | grep '^\.' | uniq`
do
  # リンクを貼らないものたち
  [[ "$f" =~ ".git" ]] && continue

  # 既にファイルが存在し、かつシンボリックリンクではない場合はバックアップ
  if [[ -e ~/"$f" ]] && [[ ! -L ~/"$f" ]]; then
    backup_time=`date +"%Y%m%d_%H%M%S"`
    mv ~/"$f" ~/"${f}.${backup_time}"
    print_info "[info] present ${f} is moved to ${f}.${backup_time}"
  fi
  ln -nfs ~/dotfiles/"$f" ~/"$f"
done
