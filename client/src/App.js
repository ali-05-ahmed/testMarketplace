import logo from './logo.svg';
import './App.css';
import { useDispatch, useSelector } from 'react-redux';
import { useEffect, useState } from 'react';
import { web3init, web3Reload, swapDaiEth, swap, uniswapSdkP, ethersinit, ethersinitReload } from './store/connectSlice';
import { create } from 'ipfs-http-client'
import ipfs from './ipfs'




function App() {
  const address = useSelector((state) => {
    return state.connectReducer.address
  })
  const accessMsg = useSelector((state) => {
    return state.connectReducer.msg
  })

  const [name, setName] = useState(null)
  const [email, setEmail] = useState(null)

  const web3 = useSelector((state) => {
    return state.connectReducer.web3
  })

  const contractName = useSelector((state) => {
    return state.connectReducer.contractName
  })
  const dispatch = useDispatch()
  const signmsg = async () => {
    if (name != null && email != null) {
      return await web3.eth.personal.sign(web3.utils.utf8ToHex(name) + web3.utils.utf8ToHex(email), address, "test password!")
    }
  }
  useEffect(() => {
    //  dispatch(web3Reload())
    dispatch(ethersinitReload())
  }, []);


  // const currentAccount = async () => {
  //   await web3.personal.sign(web3.fromUtf8("Hello from Toptal!"), web3.eth.coinbase, console.log);

  // }

  const connectWallet = () => {
    console.log("button")

    // dispatch(web3init())
    dispatch(ethersinit())
    console.log(address)

  }

  console.log(address)
  // const [fileBuffer, setFileBuffer] = useState(Buffer(""))
  const [fileUrl, setFileUrl] = useState(null)
  //const [file, setFile] = useState(null)

  let fileBuffer = null
  const captureFile = (event) => {
    event.preventDefault();
    //process for IPFS
    const file = event.target.files[0]
    const reader = new window.FileReader()
    reader.readAsArrayBuffer(file)
    reader.onloadend = () => {
      fileBuffer = Buffer(reader.result)

    }
    console.log()
  }

  const uploadFile = async (event) => {
    event.preventDefault();

    console.log('submitting form')
    try {

      await ipfs.files.add(fileBuffer, (error, result) => {
        console.log(result)
        setFileUrl(result[0].hash)
        if (error)
          console.log(error)
      })
    } catch (error) {
      console.log("error in uploading File", error)
    }
    console.log(fileUrl)
  }




  return (
    <div className="App">
      contract name : {contractName}<br></br>
      Address<br></br>
      {address}<br></br>
      {name}
      <label>Sign-Up Form</label>
      <div>
        Name <input type='text' onChange={(e) => {
          e.preventDefault()
          setName(e.target.value)
        }} required ></input>
      </div>
      <div>
        Email <input type='text' onChange={(e) => setEmail(e.target.value)} required ></input>
      </div>
      <button onClick={() => connectWallet()}>Connect</button>
      <button onClick={async () => signmsg()}>Sign</button><br></br>
      <button onClick={() => dispatch(uniswapSdkP())}>click</button><br></br>
      <div>{accessMsg}</div>
      <div>
        <form onSubmit={uploadFile}>
          <input type='file' onChange={captureFile} />
          <input type='submit' />
        </form>
      </div>



    </div >
  );
}

export default App;
