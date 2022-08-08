// App.js
import React, { useEffect, useState } from "react";
import "./App.sample.css";
/* ethers 変数を使えるようにする*/
import { ethers } from "ethers";
/* ABIファイルを含むWavePortal.jsonファイルをインポートする*/
import abi from "./utils/SocialNetwork.json";
const App = () => {
  /*
   * ユーザーのパブリックウォレットを保存するために使用する状態変数を定義します。
   */
  const [currentAccount, setCurrentAccount] = useState("");
  console.log("currentAccount: ", currentAccount);
  /*
   * デプロイされたコントラクトのアドレスを保持する変数を作成
   */
  const contractAddress = "0x73736e3D8Fe08232661845A509D28A1be6CfCeD4";
  /*
   * ABIの内容を参照する変数を作成
   */
  const contractABI = abi.abi;

  //コメント欄のコメントを保存する変数とメソッド
  const [commentValue, setCommentValue] = useState("");

  // すべてのcommentsを保存する状態変数を定義 
  const [allComments, setAllComments] = useState([]);

  const getAllComments = async () => {
    const { ethereum } = window;

    try {
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const socialNetworkContract = new ethers.Contract(
          contractAddress,
          contractABI,
          signer
        );
        /* コントラクトからgetAllCommentsメソッドを呼び出す */
        const comments = await socialNetworkContract.getAllComments();
        /* UIに必要なのは、ID、アドレス、メッセージ、タイムスタンプ、ライク数なので、以下のように設定 */
        const commentsCleaned = comments.map((comment) => {
          return {
            id: comment.id,
            address: comment.poster,
            comment: comment.comment,
            timestamp: new Date(comment.timestamp * 1000),
            totallikes: comment.totallikes
          };
        });

        /* React Stateにデータを格納する */
        setAllComments(commentsCleaned);

      } else {
        console.log("Ethereum object doesn't exist!");
      }
    } catch (error) {
      console.log(error);
    }
  };

  //コントラクトのNewCommentイベントから送られてきたデータを受け取り、処理する
  useEffect(() => {
    let socialNetworkContract;

    //新しく追加されたコメントをオブジェクト配列の末尾に保存
    const onNewComment = (id, from, comment, timestamp, totallikes ) => {
      console.log("NewComment", id, from, comment, timestamp, totallikes);
      setAllComments((prevState) => [
        ...prevState,
        {
          id: id,
          address: from,
          comment: comment,
          timestamp: new Date(timestamp * 1000),
          totallikes: totallikes
          
        },
      ]);
    };

    /* NewCommentイベントがコントラクトから発信されたときに、情報を受け取ります */
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      socialNetworkContract = new ethers.Contract(
        contractAddress,
        contractABI,
        signer
      );
      socialNetworkContract.on("NewComment", onNewComment);
    }
    /*メモリリークを防ぐために、NewCommentのイベントを解除します*/
    return () => {
      if (socialNetworkContract) {
        socialNetworkContract.off("NewComment", onNewComment);
      }
    };
  }, []);

  //コントラクトのNewLikeイベントから送られてきたデータを受け取り、処理する
  useEffect(() => {
    let socialNetworkContract;

    const onNewLike = (id, totallikes, flagCompleted ) => {
      console.log("NewLike", id, totallikes, flagCompleted);
      
      if(flagCompleted){
        const theid = id.toNumber();
        
        //新しいライク数を特定のオブジェクトのtotallikesにセットする
        setAllComments( (oldComments) => {
            return oldComments.map((oldComment, id) => {
              if (id === theid) {
                return { ...oldComment, totallikes: totallikes };
              }
              return oldComment;
            });
          }
        );
      }else{
        alert("ライクは1コメントにつき1つしか付けられません。");
      }
      
    };

    /* NewLikeイベントがコントラクトから発信されたときに、情報を受け取ります */
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      socialNetworkContract = new ethers.Contract(
        contractAddress,
        contractABI,
        signer
      );
      socialNetworkContract.on("NewLike", onNewLike);
    }
    /*メモリリークを防ぐために、NewLikeのイベントを解除します*/
    return () => {
      if (socialNetworkContract) {
        socialNetworkContract.off("NewLike", onNewLike);
      }
    };
  }, []);

  /* window.ethereumにアクセスできることを確認する関数を実装 */
  const checkIfWalletIsConnected = async () => {
    try {
      const { ethereum } = window;
      if (!ethereum) {
        console.log("Make sure you have MetaMask!");
        return;
      } else {
        console.log("We have the ethereum object", ethereum);
      }
      /* ユーザーのウォレットへのアクセスが許可されているかどうかを確認 */
      const accounts = await ethereum.request({ method: "eth_accounts" });
      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Found an authorized account:", account);
        //アカウントを設定
        setCurrentAccount(account);
        //コメントオブジェクト配列を設定
        getAllComments();
      } else {
        console.log("No authorized account found");
      }
    } catch (error) {
      console.log(error);
    }
  };
  /*
   * connectWalletメソッドを実装
   */
  const connectWallet = async () => {
    try {
      const { ethereum } = window;
      if (!ethereum) {
        alert("Get MetaMask!");
        return;
      }
      const accounts = await ethereum.request({
        method: "eth_requestAccounts",
      });
      console.log("Connected: ", accounts[0]);
      //アカウントを設定
      setCurrentAccount(accounts);
      //コメントオブジェクト配列を設定
      getAllComments();
    } catch (error) {
      console.log(error);
    }
  };
  
  //新しいコメントを投稿する関数
  const post = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        /*
         * ABIを参照
         */
        const socialNetworkContract = new ethers.Contract(
          contractAddress,
          contractABI,
          signer
        );

        //コントラクトにコメントを書き込む。
        const commentTxn = await socialNetworkContract.post(commentValue, {
          gasLimit: 300000,
        });
        
        //コメント欄を空にする
        let textareaForm = document.getElementById("message");
        textareaForm.value = '';

        console.log("Mining...", commentTxn.hash);
        await commentTxn.wait();
        console.log("Mined -- ", commentTxn.hash);

      } else {
        console.log("Ethereum object doesn't exist!");
      }
    } catch (error) {
      console.log(error);
    }
  };

  //ライクされた時に呼ばれる関数
  const like = async (num) => {
    
    const { ethereum } = window;

    try {
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const socialNetworkContract = new ethers.Contract(
          contractAddress,
          contractABI,
          signer
        );
        
        //デバッグ用 何回でもライクできる
        /*const likeTxn = await socialNetworkContract.likeForDebug(num, {
          gasLimit: 300000,
        });*/
        //１コメントにつき１人一回だけライクできる
        const likeTxn = await socialNetworkContract.like(num, {
          gasLimit: 300000,
        });
        console.log("Mining...", likeTxn.hash);
        await likeTxn.wait();
        console.log("Mined -- ", likeTxn.hash);
        
      } else {
        console.log("Ethereum object doesn't exist!");
      }
    } catch (error) {
      console.log(error);
    }
  };

  //ライク数でソートする
  const sortObjectTotalLikes = async () => {
    let copyObject = allComments;
    allComments.sort(function (a, b) {
      return a.totallikes - b.totallikes;
    });
    const commentsCleaned = copyObject.map((copy) => {
      return {
        id: copy.id,
        address: copy.address,
        comment: copy.comment,
        timestamp: copy.timestamp,
        totallikes: copy.totallikes
      };
    });
    setAllComments(commentsCleaned);
    //console.log(commentsCleaned);
  }

  //投稿日時でソートする関数
  const sortObjectTimeStamp = async () => {
    let copyObject = allComments;
    copyObject.sort(function (a, b) {
      return a.id - b.id;
    });
    const commentsCleaned = copyObject.map((copy) => {
      return {
        id: copy.id,
        address: copy.address,
        comment: copy.comment,
        timestamp: copy.timestamp,
        totallikes: copy.totallikes
      };
    });
    setAllComments(commentsCleaned);
    //console.log(commentsCleaned);
  }

  /*
   * WEBページがロードされたときに下記の関数を実行します。
   */
  useEffect(() => {
    checkIfWalletIsConnected();
  }, []);
  return (
    <div className="mainContainer">
      <div className="dataContainer">
        <div className="header">
        コメントしてね!「いいね👍」もPress!
        </div>
        <div className="bio">
          <p>１コメントにつき１人１いいねまで！</p>
          {/* 投稿日時でソートするボタンを実装 */}
          {currentAccount && (
            <button className="waveButton" onClick={sortObjectTimeStamp}>
              投稿日時で並び替え
            </button>
          )}
          {/* ライク数でソートするボタンを実装 */}
          {currentAccount && (
            <button className="waveButton" onClick={sortObjectTotalLikes}>
              ライク数で並び替え
            </button>
          )}
        </div>
        <br />
        {/* ウォレットコネクトのボタンを実装 */}
        {!currentAccount && (
          <button className="waveButton" onClick={connectWallet}>
            Connect Wallet
          </button>
        )}
        {currentAccount && (
          <p className="bio">Wallet Connected</p>
        )}
        {/* waveボタンにwave関数を連動 */}
        {currentAccount && (
          <button className="waveButton" onClick={post}>
            Post
          </button>
        )}
        {/* メッセージボックスを実装*/}
        {currentAccount && (
          <textarea
            name="messageArea"
            placeholder="メッセージはこちら"
            type="text"
            id="message"
            value={commentValue}
            onChange={(e) => setCommentValue(e.target.value)}
          />
        )}
        {/* グローバルタイムラインを表示する */}
        {currentAccount &&
          allComments
            .slice(0)
            .reverse()
            .map((comment, index) => {
              return (
                <div
                  key={comment.id.toNumber()}
                  style={{
                    backgroundColor: "#F8F8FF",
                    marginTop: "16px",
                    padding: "8px",
                  }}
                >
                  <div>Address: {comment.address}</div>
                  <div>Time: {comment.timestamp.toString()}</div>
                  <div>Comment: {comment.comment}</div>
                  <div>totallikes: {comment.totallikes.toNumber()}</div>
                  <button className="waveButton" onClick={ () => like(comment.id.toNumber()) }>
                    👍
                  </button>
                </div>
              );
            })}
      </div>
    </div>
  );
};
export default App;