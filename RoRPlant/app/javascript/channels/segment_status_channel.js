import consumer from "channels/consumer"

consumer.subscriptions.create({channel:"SegmentStatusChannel", segment_uuid:"1-2b01-0"}, {
  connected(data) {
    // Called when the subscription is ready for use on the server
    console.log("Subscribed to SegmentStatusChannel", data)
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    update_tree_statuses(data);
  },

  send_statuses: function() {
    return this.perform('send_statuses');
  }
});
