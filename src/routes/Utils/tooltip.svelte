<script module>
    export function tooltip(node, fn) {
        $effect(() => {
            const tooltip = tippy(node, fn());

            return tooltip.destroy;
        });
    }
    import { proj, ckt, settings } from "../shared.svelte.js";
    const details = {
        'switch working directory': '\n回路データのあるワークディレクトリを絶対パスで指定する',
        'readin circuit checked above': '\選択された回路を読み込む',
        'show up schematic editor': `\nチェックしていれば、${proj.schema_editor}が開きます。alta2の内部状態とは同期しないので注意！`,
        'elements and control': '\n回路に含まれる素子と制御情報です',
        'variations on device parameters': '\n素子特性を調べるときに、変化させた素子値で一挙にシミュレーションする',
        'save settings in a working directory': '\n設定情報を、ワークディレクトリに保存する',
        'load settings from a file': '\nワークディレクトリファイルから、設定情報をロードします。',
        'run LTspice simulation': '\nシミュレーションを実行します。表示中のプロットはクリアされ、プローブを設定したプロットを表示する',
        'load measurement group': '\n測定データファイルと測定条件を測定グループとして、所定の形式のcsvファイルで指定する',
        'setup simulation for measurement group': '\n測定グループのシミュレーション条件を設定する',
        'plot measurement group with simulation': '\n測定グループのシミュレーション結果をプロットする',
        'clear measurement group': '\n測定グループの設定を解除する',
        'show or hide measurement group files list': '\n測定グループのファイルリストの表示をオン・オフする',
        'push signal in probes for a current plot': '\n信号をcurrentのプロットのプローブリストに追加する',
        'show or hide plot settings': '\nプロットの設定の表示をオン・オフする',
        'make this plot current to push probes': '\nこのプロットをプローブを追加するためにcurrentにする',
        'save this plot as a CSV file': '\nこのプロットをCSVファイルにセーブする',
        'save this plot as a JSON file': '\nこのプロットをJSONファイルにセーブする',
        'get a measurement data file': '\n測定データファイルを絶対パスで指定する',
        'select two or more data columns to display in a graph': '\nグラフに表示するデータの桁番号(２つ以上）を空白で区切って指定する',
        'reverse traces in a graph': '\nグラフのトレースの表示順序を逆順にする',
        'invert X data': ' X軸のデータの符号を反転する',
        'invert Y data': ' Y軸のデータの符号を反転する',
        'select trace mode from, markers, lines, markers+lines': '\nトレースの表示を、マーカーだけ、線だけ、マーカーと線から選ぶ',
        'check all curves': '\nグラフのすべてのカーブを表示するようにチェックを入れる',
        'clear all curves': '\nグラフのすべてのカーブを削除する',
        'plot all curves': '\nグラフのすべてのカーブをプロットする',
        'set probes list (separated by comma) for a current plot': '\nこのプロットに表示するトレースをプローブのリストで指定する',
        'precision for number display for a step analysis': '\nステップ解析で表示する数字の桁数',
        'X axis is log scale if checked': '\nチェックすれば、X軸がlog表示になる',
        'Y axis is log scale if checked': '\nチェックすれば、y軸がlog表示になる',
        'clear plot': '\nグラフの表示を消す',
        'title for a graph': '\nグラフのタイトル',
        'X axis title': '\n X軸のタイトル',
        'Y axis title': '\n Y軸のタイトル',
        'performance names separated by comma': '\nカンマで区切った、パフォーマンス名',
        'performance equations in an array format': '\n中カッコで囲んだ、パフォーマンス式のリスト',
        'calculate equations for a current plot': '\nこのプロットに対して、パフォーマンス式を計算する',
        'add a new plot': '\nプロットを追加する',
        'delete this plot': '\nこのプロットを削除する',
        'add a source parameter to sweep': '\nスイープ解析のためのソースパラメータを追加する',
        'clear a last added source parameter': '\n最後に追加したソースパラメータを削除する',
        'select sweep for a source parameter': '\nソースパラメータのスイープをLinear, Decadeから選ぶ',
        'set start for a source parameter': '\nソースパラメータの初期値を設定する',
        'set stop for a source parameter': '\nソースパラメータの最終値を設定する',
        'set increment for a source parameter': '\nソースパラメータの増分を設定する',
        'set number of points per decade for a source parameter': '\nソースパラメータのdecadeあたりの点数を設定する',
        'set start for a decade sweep source parameter': '\nソースパラメータの初期値を設定する',
        'set stop for a decade sweep source parameter': '\nソースパラメータの最終値を設定する',
        'set number of points per octave for a source parameter': '\nソースパラメータのオクターブあたりの点数を設定する',
        'set start for an octave sweep source parameter': '\nソースパラメータの初期値を設定する',
        'set stop for an octave sweep source parameter': '\nソースパラメータの最終値を設定する',
        'set a list of points separated by comma for sweep source parameter': '\nソースパラメータをカンマで区切ったリストで設定する',
        'generate source parameter values': '\ソースパラメータの設定値のリストを生成する',
        'set precision for source parameter numbers': '\nソースパラメータの表示桁数を設定する',
        'add new source parameter to sweep': '\nパラメータスイープ実験のためのソースパラメータを新規に追加する',
        'delete an added source parameter': '\n追加したソースパラメータを削除する',
        'dry run a sweep experiment': '\nソースパラメータのスイープ実験の予行演習をする',
        'execute a sweep experiment': '\nソースパラメータのスイープ実験を実行する',
        'clear all experiments': '\nすべての実験結果を削除する', 
        'save experiment': '\n実験結果のグラフをJSON形式のファイルにセーブする',
        'load experiment': '\n実験結果のグラフをファイルからロードする'
       }

    export function msg(message){
        // console.log('message=', message);
        if (details[message] != undefined) {
            return {content: message + details[message]};
        } else {
            return {content: message};
        }
    }
</script>

<script lang="ts">
    import tippy from "tippy.js";
</script>
