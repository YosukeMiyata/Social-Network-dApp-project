// SocialNetwork.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract SocialNetwork {

    //新しいコメントが投稿された時のイベント、
    //コメントのインデックス、投稿者のウォレットアドレス、コメント、投稿日時、ライク数をフロントに渡す。
    //ライク数は初期は0。
    event NewComment(uint256 id, address indexed from, string comment, uint256 timestamp, uint256 totallikes);

    //ライクボタンが押された時のイベント、
    //ライクボタンが押されたコメントのインデックスと新しいライク数をフロントに渡す。
    event NewLike(uint256 id, uint256 totallikes, bool flagCompleted);
    
    //コメントに関する構造体
    struct Comment {
        uint256 id; //コメントの番号index
        address poster; //コメントを投稿したユーザーのアドレス
        string comment; // ユーザーが投稿したコメント
        uint256 timestamp; // ユーザーがコメントを投稿した日時
        uint256 totallikes; // コメントに付いたライク数
    }
    
    //任意のコメントにライクを押したユーザーのアドレスを格納する構造体
    struct Like {
        address[] uniqueUser;
    }

    //2の32乗
    uint256 constant twoToThe32thPower = 4294967295;
    //2の256乗-1
    uint256 constant twoToThe256thPower = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    //構造体Likeの中に任意の配列が存在するかどうかを示すbool変数を格納する配列
    //初期値はfalse。falseなら配列はまだ作られてない。trueなら既に配列は存在する
    bool[ twoToThe32thPower ] private arrayExists; //4294967295はコメント数の上限
    //構造体Likeの中にあるそれぞれの配列の長さを格納する配列
    uint256[ twoToThe32thPower ] private numberOfUniqueUser; //twoToThe256thPowerはライク数の上限

    //構造体
    Comment[] comments;
    //構造体
    Like[] likes;
    //ライク数の初期値
    uint256 constant initialLike = 0;
    //構造体Commentのインデックス番号
    uint256 comment_id = 0; 
    
    constructor() {
        console.log("Social Network!");
    }

    //新しいコメントが投稿された時に呼ばれる関数
    //構造体commentsに諸々の変数を格納して、次のコメントのためにcomment_idに1を足しておく
    function post(string memory _comment) public {
        
        //コメント数が適正範囲内かどうか判定
        require( comment_id < twoToThe32thPower, "The number of comments exceeds the upper limit.");

        console.log("%s posted w/ comment %s", msg.sender, _comment);
        
        //新しいコメントを構造体に格納
        comments.push( Comment( comment_id, msg.sender, _comment, block.timestamp, initialLike ) );

        //フロントに通知
        emit NewComment( comment_id, msg.sender, _comment, block.timestamp, comments[ comment_id ].totallikes );

        //indexに1つ足す
        comment_id++;
    }

    //ライクを押したユーザーが初めて押したかどうか判定する関数
    //初めてならtrueを返す。そうでないならfalseを返す。
    function isFirstLike(uint256 _ind) public returns (bool) {
        
        //まずライクされたコメントのインデックス（引数の_indがそれを示す）に対応する
        //構造体Likeの中の配列が存在するかどうか判定する
        //arrayExists[_ind]がfalseなら、配列を作るところから始める
        //trueなら既に配列は存在してるので、配列に格納されてるユニークなアドレスの中に
        //今回ライクした人のアドレスが含まれているか調べる
        
        if( arrayExists[_ind] == false ){ //配列がなければ 
            
            //配列を作る
            likes.push(Like(new address[](0)));
            //今回ライクした人のアドレスを配列に入れる
            likes[_ind].uniqueUser.push(msg.sender);
            //配列の長さを1つ増やす
            numberOfUniqueUser[_ind] = numberOfUniqueUser[_ind] + 1;
            console.log(likes[_ind].uniqueUser[0]);
            //配列は既に作ったことを知らせる
            arrayExists[_ind] = true;
            console.log("true");
            //この人はユニークなユーザーですよという意味でtrueを返す
            return true;
        
        }else{ //既に配列が存在していれば
            
            //ユニークユーザーかどうかを調べるためのbool変数
            bool isUnique = true;
            //for文でライクが押されたコメントのインデックスに対応する配列の中に
            //今回ライクを押した人のアドレスと同じものがあるかどうか調べる。
            //同じものがあれば、isUniqueにfalseを代入。
            //同じものがなければ、ユニークなアドレスなのでtrueのまま。
            for(uint i = 0; i < numberOfUniqueUser[_ind]; i++){
                if( likes[_ind].uniqueUser[i] == msg.sender){
                    isUnique = false;
                }
            }

            if( isUnique ){ //for文を抜けたあとにisUniqueがtrueのままなら
                //配列に今回ライクした人のアドレスを入れる
                likes[_ind].uniqueUser.push(msg.sender);
                console.log(likes[_ind].uniqueUser[ numberOfUniqueUser[_ind] ]);
                //配列の長さに1を足す
                numberOfUniqueUser[_ind] = numberOfUniqueUser[_ind] + 1;
                console.log("OK true");
                //この人はユニークなユーザーですよという意味でtrueを返す
                return true;
            }
            else{ //for文を抜けたあとにisUniqueがfalseになっていたら
                console.log("false");
                //この人は同じコメントにライクをしようとしてますよという意味でfalseを返す
                return false;
            }
        
        }
        
    }

    //新しくライクが押された時に呼ばれる関数
    //引数の_numは、構造体commentsのインデックスを指定する。
    //構造体commentsのtotallikesに1を足して、フロントに通知
    function like(uint256 _num) public {
        
        //ライク数が適正範囲内かどうか判定
        //require( numberOfUniqueUser[ _num ] < twoToThe256thPower, "The number of likes exceeds the upper limit.");

        bool isFirst = isFirstLike( _num );
        console.log("%s likeed w/ at the comment", msg.sender);
        
        if( isFirst ){
            
            console.log("total likes is %i", comments[ _num ].totallikes);
            //ライク数に1を足す
            comments[ _num ].totallikes++;
            console.log("total likes is %i", comments[ _num ].totallikes);

            //フロントに通知
            emit NewLike( comments[ _num ].id, comments[ _num ].totallikes, true );
        
        }else{
            console.log("Only One Time!");
            emit NewLike( comments[ _num ].id, comments[ _num ].totallikes, false );
        }
    }

    //デバッグ用
    //上のlike関数は同じ人が同じコメントにライクできないようになっているので、
    //こっちは同じ人がいくらでもライク数を増やせる
    function likeForDebug(uint256 _num) public {
        
        
        //ライク数が適正範囲内かどうか判定
        require( numberOfUniqueUser[ _num ] < twoToThe256thPower, "The number of likes exceeds the upper limit.");

        console.log("total likes is %i", comments[ _num ].totallikes);
        //ライク数に1を足す
        comments[ _num ].totallikes++;
        console.log("total likes is %i", comments[ _num ].totallikes);

        //フロントに通知
        emit NewLike( comments[ _num ].id, comments[ _num ].totallikes, true );

    }

    //全てのcommentsを返す関数
    function getAllComments() public view returns (Comment[] memory) {
        return comments;
    }

}