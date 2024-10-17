import { PLVCommonConstants, PLVLiveChannelType, PLVLiveSceneSDK, PLVLogger, PLVTextUtils, PLVToastUtils, PLVUserConstants, PLVUtils, pushToWatchPage } from 'scenes_live';

const TAG = '[PLVLoginPage]'

@Entry
@Component
struct PLVLoginPage {
  // live data
  @State @Watch('onDataChanged') liveUserId: string = ''
  @State @Watch('onDataChanged') liveChannelId: string = ''
  @State @Watch('onDataChanged') liveAppId: string = ''
  @State @Watch('onDataChanged') liveAppSecret: string = ''
  // playback data
  @State @Watch('onDataChanged') playbackUserId: string = ''
  @State @Watch('onDataChanged') playbackChannelId: string = ''
  @State @Watch('onDataChanged') playbackAppId: string = ''
  @State @Watch('onDataChanged') playbackAppSecret: string = ''
  @State playbackVid: string = ''
  @State isOnVodList: boolean = false
  // common data
  @State @Watch('onDataChanged') tabSelIndex: number = 0
  @State loginButtonEnabled: boolean = PLVTextUtils.checkValidDataLength(this.liveUserId, this.liveChannelId, this.liveAppId, this.liveAppSecret)
  @State loadingVisibility: Visibility = Visibility.None
  viewerId?: string
  viewerName?: string
  viewerAvatar?: string

  override async aboutToAppear(): Promise<void> {
    // todo 请务必在这里替换为你的学员(用户)ID，设置学员(用户)ID的意义详细可以查看：https://github.com/polyv/polyv-android-cloudClass-sdk-demo/wiki/6-设置学员唯一标识的意义
    this.viewerId = PLVUtils.getDeviceId()
    // todo 请务必在这里替换为你的学员(用户)昵称
    this.viewerName = '观众' + this.viewerId?.substring(0, 6)
    // todo 在这里可替换为你的学员(用户)头像地址
    this.viewerAvatar = PLVUserConstants.STUDENT_AVATAR_URL
  }

  build() {
    Stack() {
      Column() {
        Text('直播带货')
          .fontSize(30)
          .fontColor(Color.Gray)
          .margin({ top: 30 })
        Tabs({ barPosition: BarPosition.Start }) {
          TabContent() {
            Column({ space: 36 }) {
              TextInput({ placeholder: '用户Id', text: $$this.liveUserId })
                .showUnderline(true)
              TextInput({ placeholder: '频道Id', text: $$this.liveChannelId })
                .showUnderline(true)
              TextInput({ placeholder: 'AppId', text: $$this.liveAppId })
                .showUnderline(true)
              TextInput({ placeholder: 'AppSecret', text: $$this.liveAppSecret })
                .showUnderline(true)
            }
          }
          .tabBar('直播')

          TabContent() {
            Column({ space: 15 }) {
              TextInput({ placeholder: '用户Id', text: $$this.playbackUserId })
                .showUnderline(true)
              TextInput({ placeholder: '频道Id', text: $$this.playbackChannelId })
                .showUnderline(true)
              TextInput({ placeholder: 'AppId', text: $$this.playbackAppId })
                .showUnderline(true)
              TextInput({ placeholder: 'AppSecret', text: $$this.playbackAppSecret })
                .showUnderline(true)
              TextInput({ placeholder: '视频Id', text: $$this.playbackVid })
                .showUnderline(true)
              Row() {
                Text('点播列表')
                  .margin({ left: 10, right: 6 })
                Toggle({ type: ToggleType.Switch, isOn: $$this.isOnVodList })
              }.width(PLVCommonConstants.FULL_PERCENT)
            }
          }
          .tabBar('回放')
        }
        .onChange((index) => {
          this.tabSelIndex = index
        })
        .margin({ top: 30 })
        .height(424)

        Button('登录')
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(48)
          .enabled(this.loginButtonEnabled)
          .onClick(() => {
            this.loadingVisibility = Visibility.Visible
            if (this.tabSelIndex == 0) {
              this.loginLive()
            } else {
              this.loginPlayback()
            }
          })
        Text('2013 – 2024 易方信息科技股份有限公司 版权所有')
          .fontSize(14)
          .fontColor(Color.Gray)
          .align(Alignment.Bottom)
          .margin({ bottom: 16 })
          .layoutWeight(1)
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .padding(18)
      .alignItems(HorizontalAlign.Center)

      Stack() {
        Stack() {
        }
        .backgroundColor(Color.Gray)
        .opacity(0.5)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

        Row() {
          LoadingProgress()
            .width(36)
            .height(36)
          Text('正在登录中，请稍等...')
            .fontSize(16)
        }
        .padding(12)
        .border({ radius: 4 })
        .backgroundColor(Color.White)
      }
      .visibility(this.loadingVisibility)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
  }

  onDataChanged(propName: string): void {
    this.loginButtonEnabled = this.tabSelIndex == 0
      ? PLVTextUtils.checkValidDataLength(this.liveUserId, this.liveChannelId, this.liveAppId, this.liveAppSecret)
      : PLVTextUtils.checkValidDataLength(this.playbackUserId, this.playbackChannelId, this.playbackAppId, this.playbackAppSecret)
  }

  createSDK(): PLVLiveSceneSDK {
    const sdk: PLVLiveSceneSDK = PLVLiveSceneSDK.create()
    sdk.channelData.viewerId = this.viewerId
    sdk.channelData.viewerName = this.viewerName
    sdk.channelData.viewerAvatar = this.viewerAvatar
    return sdk
  }

  loginLive() {
    const sdk = this.createSDK()
    sdk.loginManager.loginLive(this.liveUserId, this.liveChannelId, this.liveAppId, this.liveAppSecret)
      .then((channelData) => {
        if (PLVLiveChannelType.ALONE != channelData.channelType) {
          PLVLogger.error(TAG, `loginLive error while channelType=${channelData.channelType}`)
          PLVToastUtils.shortShow('直播带货场景仅支持纯视频频道类型')
          this.loadingVisibility = Visibility.None
          sdk.destroy()
          return
        }
        PLVLogger.info(TAG, `loginLive success`)
        this.loadingVisibility = Visibility.None
        pushToWatchPage(sdk.uniqueId)
      })
      .catch((err: Error) => {
        this.loadingVisibility = Visibility.None
        PLVToastUtils.shortShow(`loginLive error: ${err.message}`)
        sdk.destroy()
      })
  }

  loginPlayback() {
    const sdk = this.createSDK()
    sdk.loginManager.loginPlayback(this.playbackUserId, this.playbackChannelId, this.playbackAppId, this.playbackAppSecret, this.playbackVid)
      .then((channelData) => {
        if (PLVLiveChannelType.ALONE != channelData.channelType) {
          PLVLogger.error(TAG, `loginPlayback error while channelType=${channelData.channelType}`)
          PLVToastUtils.shortShow('直播带货场景仅支持纯视频频道类型')
          this.loadingVisibility = Visibility.None
          sdk.destroy()
          return
        }
        PLVLogger.info(TAG, `loginPlayback success`)
        this.loadingVisibility = Visibility.None
        sdk.channelData.setupPlaybackListType(this.isOnVodList)
        pushToWatchPage(sdk.uniqueId)
      })
      .catch((err: Error) => {
        PLVToastUtils.shortShow(`loginPlayback error: ${err.message}`)
        this.loadingVisibility = Visibility.None
        sdk.destroy()
      })
  }
}