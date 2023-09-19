import consumer from "channels/consumer"
// SegmentMeasurementsChannel
consumer.subscriptions.create({channel:"SegmentMeasurementsChannel", segment_uuid:"1-2b01-0"}, {
  connected() {
    // Called when the subscription is ready for use on the server
    window.console.log("Subscribed!")
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    window.console.log("Received "+JSON.stringify(data));
    for (const m of data) append_plot_data(m);
  },

  send_measurement: function() {
    return this.perform('send_measurement');
  }
});
