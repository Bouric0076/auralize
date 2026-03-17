# Future Features & Roadmap

## 🎧 Group Session / Wi-Fi Sync (Audio Separation)
Since native Bluetooth dual-audio isn't supported on all devices, we can implement a software solution using Wi-Fi.

- [ ] **Feasibility Study**: Research methods for syncing audio playback across devices over local Wi-Fi.
    - Potential libraries: `socket_io_client` (for signaling), `udp` (for audio data).
    - Clock synchronization strategies (NTP-like logic) to handle latency.
- [ ] **Host Mode**:
    - Broadcast session availability.
    - Stream audio chunks or sync signals to connected guests.
- [ ] **Guest Mode**:
    - Discover host sessions.
    - Buffer and play audio in sync with host.
- [ ] **UI/UX**:
    - "Party Mode" toggle.
    - List of connected devices.
    - Latency adjustment slider.
