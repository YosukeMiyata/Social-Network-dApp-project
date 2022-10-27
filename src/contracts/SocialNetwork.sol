// SocialNetwork.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "hardhat/console.sol";

// 最初にOpenZeppelinライブラリをインポートします.
import "@openzeppelin/contracts/utils/Counters.sol";

contract SocialNetwork {

    // OpenZeppelinによりtokenIdsの追跡が容易になります。
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //新しいコメントが投稿された時のイベント、
    //コメントのインデックス、投稿者のウォレットアドレス、コメント、投稿日時、ライク数をフロントに渡す。
    //ライク数は初期は0。
    event NewComment(uint256 id, address indexed from, string comment, uint256 timestamp, uint256 totallikes);

    //ライクボタンが押された時のイベント、
    //ライクボタンが押されたコメントのインデックスと新しいライク数をフロントに渡す。
    event NewLike(uint256 id, uint256 totallikes, bool flagCompleted);

    event Transfer(address _from, address _to, uint256 _value);
    
    //コメントに関する構造体
    struct Comment {
        uint256 id; //コメントの番号index
        address poster; //コメントを投稿したユーザーのアドレス
        string comment; // ユーザーが投稿したコメント
        uint256 timestamp; // ユーザーがコメントを投稿した日時
        uint256 totallikes; // コメントに付いたライク数
    }
    
    struct Favorite {
        mapping(address => bool) isFavorite;
        // address毎に既にいいねしているかのbooleanを紐づける
    }

    mapping(uint256 => Favorite) favorites;
        // 投稿ID毎にFavorite構造体を紐づける
    mapping(address => uint) balance;

    //構造体
    Comment[] comments;

    //ライク数の初期値
    uint256 constant initialLike = 0;

    //uint256 numnum = 0;
    
    constructor() payable {
        console.log("Social Network!");
    }

    //新しいコメントが投稿された時に呼ばれる関数
    //構造体commentsに諸々の変数を格納して、次のコメントのために_tokenIdsに1を足しておく
    function post(string memory _comment) public {
        
        uint256 newRecordId = _tokenIds.current();

        console.log("%s posted w/ comment %s", msg.sender, _comment);
        
        Favorite storage f = favorites[ newRecordId ];
        f.isFavorite[ msg.sender ] = false;
        
        //新しいコメントを構造体に格納
        comments.push( Comment( newRecordId, msg.sender, _comment, block.timestamp, initialLike ) );

        //フロントに通知
        emit NewComment( newRecordId, msg.sender, _comment, block.timestamp, comments[ newRecordId ].totallikes );

        _tokenIds.increment();
    }

    //新しくライクが押された時に呼ばれる関数
    //引数の_numは、構造体commentsのインデックスを指定する。
    //構造体commentsのtotallikesに1を足して、フロントに通知
    function like(uint256 _num) public {
        
        Favorite storage f = favorites[ _num ];
        
        if( f.isFavorite[ msg.sender ] == false ){
            
            f.isFavorite[ msg.sender ] = true;
            
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
        console.log("%s likeed w/ at the comment", msg.sender);

    }

    //デバッグ用
    //上のlike関数は同じ人が同じコメントにライクできないようになっているので、
    //こっちは同じ人がいくらでもライク数を増やせる
    function likeForDebug(uint256 _num) public {
        
        console.log("total likes is %i", comments[ _num ].totallikes);
        //ライク数に1を足す
        comments[ _num ].totallikes++;
        console.log("total likes is %i", comments[ _num ].totallikes);

        //フロントに通知
        emit NewLike( comments[ _num ].id, comments[ _num ].totallikes, true );

    }

    modifier balanceCheck( uint _amount ){
        require( balance[ msg.sender ] >= _amount, "Insufficient balance" );
        _;
    }

    function getBalance() public view returns( uint ){
        return balance[ msg.sender ];
    }

    function deposit() public payable {
        balance[ msg.sender ] += msg.value;
    }

    function withdraw(uint _amount) public balanceCheck( _amount ) {
        
        balance[ msg.sender ] -= _amount;
        payable( msg.sender ).transfer( _amount );
    }

    function transfer(uint256 _num, uint256 _value) public returns (bool success) {
        // 移動したい額のトークンがユーザーのアドレスに存在するか確認
        // 存在しない場合は、エラーを返す
        require( _value > 0, "value can't be 0" );

        balance[msg.sender] += _value;
        // 関数を呼び出したユーザーアドレスから _value の金額を引き抜く
        balance[msg.sender] -= _value;
        // 送金先のアドレスに _value の金額を足す
        balance[ comments[ _num ].poster ] += _value;
        
        // Transferイベントを実行する
        emit Transfer(msg.sender, comments[ _num ].poster, _value);
        
        return true;
    }

    //全てのcommentsを返す関数
    function getAllComments() public view returns (Comment[] memory) {
        return comments;
    }

    function getIsFavorite( uint256 _num ) public view returns ( bool ) {
        
        Favorite storage f = favorites[ _num ];
        
        return f.isFavorite[ msg.sender ];

    }

}