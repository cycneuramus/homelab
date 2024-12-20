<?xml version="1.0" encoding="utf-8"?>
<EncodingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <EncodingThreadCount>-1</EncodingThreadCount>
  <TranscodingTempPath>/config/data/transcodes</TranscodingTempPath>
  <FallbackFontPath />
  <EnableFallbackFont>false</EnableFallbackFont>
  <DownMixAudioBoost>2</DownMixAudioBoost>
  <MaxMuxingQueueSize>2048</MaxMuxingQueueSize>
  <EnableThrottling>false</EnableThrottling>
  <ThrottleDelaySeconds>180</ThrottleDelaySeconds>
  {{- if or (eq (env "attr.unique.hostname") "apex") (eq (env "attr.unique.hostname") "ambi") (eq (env "attr.unique.hostname") "horreum") }}
  <HardwareAccelerationType>vaapi</HardwareAccelerationType>
  {{- else -}}
  <HardwareAccelerationType xsi:nil="true" />
  {{ end -}}
  <EncoderAppPath>/usr/lib/jellyfin-ffmpeg/ffmpeg</EncoderAppPath>
  <EncoderAppPathDisplay>/usr/lib/jellyfin-ffmpeg/ffmpeg</EncoderAppPathDisplay>
  <VaapiDevice>/dev/dri/renderD128</VaapiDevice>
  <EnableTonemapping>false</EnableTonemapping>
  <EnableVppTonemapping>false</EnableVppTonemapping>
  <TonemappingAlgorithm>bt2390</TonemappingAlgorithm>
  <TonemappingMode>auto</TonemappingMode>
  <TonemappingRange>auto</TonemappingRange>
  <TonemappingDesat>0</TonemappingDesat>
  <TonemappingPeak>100</TonemappingPeak>
  <TonemappingParam>0</TonemappingParam>
  <VppTonemappingBrightness>0</VppTonemappingBrightness>
  <VppTonemappingContrast>1.2</VppTonemappingContrast>
  <H264Crf>23</H264Crf>
  <H265Crf>28</H265Crf>
  <EncoderPreset xsi:nil="true" />
  <DeinterlaceDoubleRate>false</DeinterlaceDoubleRate>
  <DeinterlaceMethod>yadif</DeinterlaceMethod>
  <EnableDecodingColorDepth10Hevc>true</EnableDecodingColorDepth10Hevc>
  <EnableDecodingColorDepth10Vp9>true</EnableDecodingColorDepth10Vp9>
  <EnableEnhancedNvdecDecoder>true</EnableEnhancedNvdecDecoder>
  <PreferSystemNativeHwDecoder>true</PreferSystemNativeHwDecoder>
  {{- if eq (env "attr.unique.hostname") "horreum" }}
  <EnableIntelLowPowerH264HwEncoder>true</EnableIntelLowPowerH264HwEncoder>
  <EnableIntelLowPowerHevcHwEncoder>true</EnableIntelLowPowerHevcHwEncoder>
  {{- else -}}
  <EnableIntelLowPowerH264HwEncoder>false</EnableIntelLowPowerH264HwEncoder>
  <EnableIntelLowPowerHevcHwEncoder>false</EnableIntelLowPowerHevcHwEncoder>
  {{ end -}}
  <EnableHardwareEncoding>true</EnableHardwareEncoding>
  <AllowHevcEncoding>false</AllowHevcEncoding>
  <EnableSubtitleExtraction>true</EnableSubtitleExtraction>
  <HardwareDecodingCodecs>
    <string>h264</string>
    <string>hevc</string>
    <string>mpeg2video</string>
    <string>vc1</string>
    <string>vp8</string>
    <string>vp9</string>
    <string>av1</string>
  </HardwareDecodingCodecs>
  <AllowOnDemandMetadataBasedKeyframeExtractionForExtensions>
    <string>mkv</string>
  </AllowOnDemandMetadataBasedKeyframeExtractionForExtensions>
</EncodingOptions>
