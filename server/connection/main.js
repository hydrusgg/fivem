exports('createWebSocket', (url, headers, listener) => {
  let handle

  const instance = {
    get_state() {
      return handle.readyState
    },
    ping() {
      handle.ping()
    },
    close() {
      handle.close()
    },
    send(data) {
      handle.send(data)
    },
    reconnect() {
      if (handle) {
        handle.close()
      }
      handle = new WebSocket(url, { headers })
      handle.onmessage = ({ data }) => {
        const { event, payload } = JSON.parse(data.toString('utf8'))
        listener(event, payload)
      }
      handle.onclose = () => listener('$close', {})
      handle.onopen = () => listener('$open', {})
      handle.onerror = (err) => listener('$error', err.message)
    }
  }

  instance.reconnect()

  return instance
})