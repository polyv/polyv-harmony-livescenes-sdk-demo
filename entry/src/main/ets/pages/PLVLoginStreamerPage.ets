import {
  DerivedState,
  isTextEmpty,
  kvStore,
  MutableState,
  PLVKVStore,
  MutableObserver,
  runCatching,
  RequirePermissions
} from '@polyvharmony/media-player-sdk'
import { PLVLiveSceneSDK, PLVToastUtils, PLVWebUtils } from 'scenes_live'
import { routerToStreamerAlone } from 'scenes_streamerAlone'
import { window } from '@kit.ArkUI'

@Entry
@Component
struct PLVLoginStreamerPage {
  private localChannelId: PLVKVStore<String> = kvStore("plv_login_streamer_channel_id", String)
  private localPassword: PLVKVStore<String> = kvStore("plv_login_streamer_password", String)
  private localNickname: PLVKVStore<String> = kvStore("plv_login_streamer_nickname", String)
  private localRememberPassword: PLVKVStore<Boolean> = kvStore("plv_login_streamer_remember_password", Boolean)
  private localAgreeContract: PLVKVStore<Boolean> = kvStore("plv_login_streamer_agree_contract", Boolean)
  private stateChannelId = new MutableState<string>()
  private statePassword = new MutableState<string>()
  private stateNickname = new MutableState<string>()
  private stateAgreeContract = new MutableState<boolean>()
  private stateLoginRequesting = new MutableState<boolean>(false)
  private stateLoginEnable = new DerivedState(() => {
    return !isTextEmpty(this.stateChannelId.value)
      && !isTextEmpty(this.statePassword.value)
      && !this.stateLoginRequesting.value
  })
  @State private arkChannelId: string = ""
  @State private arkPassword: string = ""
  @State private arkNickname: string = ""
  @State private arkLoginEnable: boolean = true
  @State private arkRememberPassword: boolean = false
  @State private arkAgreeContract: boolean = false
  private observers: MutableObserver[] = []

  async aboutToAppear() {
    this.stateChannelId.observe(it => this.arkChannelId = it).pushTo(this.observers)
    this.statePassword.observe(it => this.arkPassword = it).pushTo(this.observers)
    this.stateNickname.observe(it => this.arkNickname = it).pushTo(this.observers)
    this.stateAgreeContract.observe(it => this.arkAgreeContract = it).pushTo(this.observers)
    this.stateLoginEnable.observe(it => this.arkLoginEnable = it).pushTo(this.observers)

    this.stateChannelId.value = (await this.localChannelId.get())?.valueOf() ?? ""
    this.statePassword.value = (await this.localPassword.get())?.valueOf() ?? ""
    this.stateNickname.value = (await this.localNickname.get())?.valueOf() ?? ""
    this.stateAgreeContract.value = (await this.localAgreeContract.get())?.valueOf() ?? false
    this.arkRememberPassword = (await this.localRememberPassword.get())?.valueOf() ?? false
  }

  async onPageShow() {
    const windowInstance = await window.getLastWindow(getContext(this))
    windowInstance.setPreferredOrientation(window.Orientation.PORTRAIT)
  }

  build() {
    Stack() {
      Image($r('app.media.plv_streamer_login_bg'))
        .objectFit(ImageFit.Cover)
        .expandSafeArea()

      Column() {
        Text($r('app.string.plv_login_streamer_live_broadcast'))
          .fontSize(30)
          .fontColor('#F0F1F5')
          .fontWeight(FontWeight.Bold)
          .letterSpacing(4)
          .margin({
            top: 36
          })

        Column() {
          TextInput({
            placeholder: $r('app.string.plv_login_streamer_enter_channel_number'),
            text: this.arkChannelId
          })
            .height(44)
            .fontSize(14)
            .fontColor('#F0F1F5')
            .placeholderColor('#99F0F1F5')
            .borderRadius(30)
            .backgroundColor('#29FFFFFF')
            .margin({
              top: 64
            })
            .stateStyles({
              focused: {
                .borderColor('#4399FF')
                .borderWidth(1)
              }
            })
            .cancelButton({
              style: CancelButtonStyle.INPUT,
              icon: {
                size: 12,
                src: $r('app.media.plv_login_input_delete')
              }
            })
            .onChange(text => {
              this.stateChannelId.value = text
            })

          TextInput({
            placeholder: $r('app.string.plv_login_streamer_enter_password'),
            text: this.arkPassword
          })
            .type(InputType.NEW_PASSWORD)
            .height(44)
            .fontSize(14)
            .fontColor('#F0F1F5')
            .placeholderColor('#99F0F1F5')
            .borderRadius(30)
            .backgroundColor('#29FFFFFF')
            .margin({
              top: 16
            })
            .stateStyles({
              focused: {
                .borderColor('#4399FF')
                .borderWidth(1)
              }
            })
            .cancelButton({
              style: CancelButtonStyle.INPUT,
              icon: {
                size: 12,
                src: $r('app.media.plv_login_input_delete')
              }
            })
            .passwordIcon({
              onIconSrc: $r('app.media.plv_login_password_show'),
              offIconSrc: $r('app.media.plv_login_password_hide')
            })
            .onChange(text => {
              this.statePassword.value = text
            })

          TextInput({
            placeholder: $r('app.string.plv_login_streamer_enter_nickname'),
            text: this.arkNickname
          })
            .height(44)
            .fontSize(14)
            .fontColor('#F0F1F5')
            .placeholderColor('#99F0F1F5')
            .borderRadius(30)
            .backgroundColor('#29FFFFFF')
            .margin({
              top: 16
            })
            .stateStyles({
              focused: {
                .borderColor('#4399FF')
                .borderWidth(1)
              }
            })
            .cancelButton({
              style: CancelButtonStyle.INPUT,
              icon: {
                size: 12,
                src: $r('app.media.plv_login_input_delete')
              }
            })
            .onChange(text => {
              this.stateNickname.value = text
            })

          Button($r('app.string.plv_login_streamer_login'))
            .width('100%')
            .height(44)
            .enabled(this.arkLoginEnable)
            .fontColor('#F0F1F5')
            .backgroundColor('#4399FF')
            .borderRadius(30)
            .margin({
              top: 64
            })
            .onClick(async () => {
              const agreeContract = this.arkAgreeContract
              if (!agreeContract) {
                PLVToastUtils.shortShow($r('app.string.plv_login_streamer_check_the_agreement'))
                return
              }
              this.stateLoginRequesting.value = true
              const channelId = this.arkChannelId
              const password = this.arkPassword
              const nickname = this.arkNickname
              const rememberPassword = this.arkRememberPassword
              const sdk = PLVLiveSceneSDK.create()
              const result = await runCatching(sdk.loginManager.loginStreamer(channelId, password, nickname))
              if (result.success === false) {
                PLVToastUtils.shortShow(`loginStreamer error: ${result.error.message}`)
                sdk.destroy()
              } else {
                if (rememberPassword) {
                  this.localChannelId.set(channelId)
                  this.localPassword.set(password)
                  this.localNickname.set(nickname)
                } else {
                  this.localChannelId.set("")
                  this.localPassword.set("")
                  this.localNickname.set("")
                }
                this.localRememberPassword.set(rememberPassword)
                this.gotoStreamerPage(sdk)
              }
              this.stateLoginRequesting.value = false
            })
        }
        .width('100%')
        .padding({
          left: 40,
          right: 40
        })

        Row() {
          Checkbox()
            .width(16)
            .height(16)
            .select($$this.arkRememberPassword)
          Text($r('app.string.plv_login_streamer_remember_password'))
            .fontColor('#99F0F1F5')
            .fontSize(12)
        }
        .width('100%')
        .padding({
          left: 57
        })
        .margin({
          top: 19
        })

        Row() {
          Checkbox()
            .width(16)
            .height(16)
            .select(this.arkAgreeContract)
            .onChange(agree => {
              this.stateAgreeContract.setValue(agree)
              this.localAgreeContract.set(agree)
            })
          Text($r('app.string.plv_login_streamer_read_and_agree'))
            .fontColor('#99F0F1F5')
            .fontSize(12)
          Text($r('app.string.plv_login_streamer_privacy_policy'))
            .fontColor('#F0F1F5')
            .fontSize(12)
            .onClick(() => this.gotoPrivacyPolicy())
          Text($r('app.string.plv_login_streamer_and'))
            .fontColor('#99F0F1F5')
            .fontSize(12)
          Text($r('app.string.plv_login_streamer_user_agreement'))
            .fontColor('#F0F1F5')
            .fontSize(12)
            .onClick(() => this.gotoUserAgreement())
        }
        .width('100%')
        .padding({
          left: 57
        })
        .margin({
          top: 5
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @RequirePermissions('ohos.permission.CAMERA', 'ohos.permission.MICROPHONE')
  private gotoStreamerPage(sdk: PLVLiveSceneSDK) {
    routerToStreamerAlone(sdk)
  }

  private gotoPrivacyPolicy() {
    PLVWebUtils.openWebLink('https://s2.videocc.net/app-simple-pages/privacy-policy/index.html')
  }

  private gotoUserAgreement() {
    PLVWebUtils.openWebLink('https://s2.videocc.net/app-simple-pages/user-agreement/index.html')
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}