# Examples

The following examples demonstrate the use of the Ballerina WhatsApp Business Cloud connector.

1. [Send a WhatsApp message](send-message) — send a text message and receive replies/status updates
   over a webhook listener.

## Running an example

Each example is a standalone Ballerina package. Provide the required configuration in a `Config.toml`
in the example directory, then run:

```bash
bal run
```

## Building the examples with the local connector

To build all examples against the connector built from this repository (without pulling it from
Ballerina Central), run from the `examples/` directory:

```bash
./build.sh build   # or: ./build.sh run
```

This packs the connector, pushes it to the local repository, mirrors it into the central cache, then
builds/runs each example in offline mode.
