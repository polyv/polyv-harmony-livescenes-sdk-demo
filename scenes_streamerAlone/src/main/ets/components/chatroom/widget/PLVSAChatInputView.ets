import {
  PLVBaseIdEvent,
  PLVChatImgEvent,
  PLVChatQuoteDataBean,
  PLVChatroomError,
  PLVChatroomErrorCode,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVEmotionImageBean,
  PLVLazyDataSource,
  PLVLiveSceneSDK,
  PLVLocalSpeakEvent,
  PLVLogger,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, runCatching, Disposable } from '@polyvharmony/media-player-sdk'
import { PhotoPickerComponent, PickerController, SelectMode } from '@ohos.file.PhotoPickerComponent'
import { ClickType, ItemInfo, ItemType, photoAccessHelper } from '@kit.MediaLibraryKit'
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus'

const TAG = '[PLVSAChatInputView]'

@Preview
@Component
export struct PLVSAChatInputView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  chatListScroller: ListScroller = new ListScroller()
  @Link fullChatListData: PLVLazyDataSource<PLVBaseIdEvent>
  @Link isShowChatInputLayout: boolean
  @Link reply: PLVChatQuoteDataBean | undefined
  @LocalStorageLink('chatInputText') chatInputText: string = ''
  @State private emotionSelectPanelVisible: boolean = false
  @State private localImagePickerVisible: boolean = false
  private readonly localImagePickerDialog = new CustomDialogController({
    builder: PLVSAChatLocalImageSelectDialog({
      localImagePickerVisible: this.localImagePickerVisible,
      onSelectImage: (image: string) => {
        this.sendLocalImage(image)
        this.localImagePickerDialog.close()
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })
  private onBackPressDisposable: Disposable | null = null

  aboutToAppear(): void {
    this.onBackPressDisposable = this.pageDataBus.onBackPressHandler.register(20, () => this.onBackPress())
  }

  build() {
    Column() {
      Blank()
        .onTouch(() => this.isShowChatInputLayout = false)
      if (this.reply) {
        Row() {
          Text(this.replyText())
            .fontSize(12)
            .fontColor('#F0F1F5')
            .wordBreak(WordBreak.BREAK_ALL)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
            .constraintSize({ maxWidth: '85%' })
            .padding({ left: 16, right: 10 })
          Blank()
          Image($r('app.media.plvsa_chat_quote_message_close_icon'))
            .width(32)
            .height(32)
            .padding(6)
            .margin({ right: 4 })
            .draggable(false)
            .onClick(() => {
              this.reply = undefined
            })
        }
        .onTouch((event) => {
          event.stopPropagation()
        })
        .width(PLVCommonConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Center)
        .height(48)
        .backgroundColor('#1B202D')
      }

      Row() {
        TextInput({ placeholder: this.inputPlaceText(), text: $$this.chatInputText })
          .height(32)
          .layoutWeight(1)
          .enterKeyType(EnterKeyType.Send)
          .onSubmit((key, event) => {
            event.keepEditableState()
            this.speak()
          })
          .onAppear(() => {
            focusControl.requestFocus('chatTextInput')
          })
          .fontSize(14)
          .padding({ left: 16, right: 16 })
          .margin({
            right: 8
          })
          .placeholderColor('#4cffffff')
          .fontColor('#F0F1F5')
          .maxLength(200)
          .maxLines(1)
          .backgroundColor('#80464646')
          .borderRadius(4)
          .id('chatTextInput')

        Image($r("app.media.plvsa_chat_input_emotion_icon"))
          .width(32)
          .height(32)
          .padding(2)
          .onClick(() => {
            this.emotionSelectPanelVisible = !this.emotionSelectPanelVisible
          })
        Image($r("app.media.plvsa_chat_select_image_icon"))
          .width(32)
          .height(32)
          .padding(2)
          .onClick(() => {
            this.localImagePickerDialog.open()
          })
      }
      .onTouch((event) => {
        event.stopPropagation()
      })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(44)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#535353')

      if (this.emotionSelectPanelVisible) {
        PLVSAChatEmotionLayout({
          onClickEmotionImage: (emotion: PLVEmotionImageBean) => {
            this.sendEmotionImage(emotion)
          }
        })
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  private speak() {
    if (this.chatInputText.trim().length == 0) {
      PLVToastUtils.shortShow($r('app.string.plvsa_chat_toast_send_text_empty'))
      return
    }
    const handleSendSuccess = (event: PLVLocalSpeakEvent) => {
      this.fullChatListData.pushData(event)
      this.chatListScroller.scrollEdge(Edge.Bottom)
      this.isShowChatInputLayout = false
      this.chatInputText = ''
      this.reply = undefined
    }
    this.sdk?.chatroomManager.speak(this.chatInputText, this.reply)
      .then((speakEvent) => {
        handleSendSuccess(speakEvent)
      })
      .catch((err: PLVChatroomError) => {
        PLVLogger.printError(TAG, `speak fail`, err as Error)
        if (PLVChatroomErrorCode.USER_IS_BANNED == err.code) {
          // 被禁言也认为发言成功，并添加到聊天列表中，但不会广播给其他用户
          handleSendSuccess(err.data as PLVLocalSpeakEvent)
        } else {
          PLVToastUtils.shortShow(`speak fail: ${err.message}`)
        }
      })
  }

  private async sendEmotionImage(emotion: PLVEmotionImageBean): Promise<void> {
    const result = await runCatching(this.sdk?.chatroomManager.sendEmotionImage(emotion))
    const handleSendSuccess = (event: PLVEmotionEvent) => {
      this.fullChatListData.pushData(event)
      this.chatListScroller.scrollEdge(Edge.Bottom)
      this.isShowChatInputLayout = false
    }
    if (result.success === true) {
      handleSendSuccess(result.data)
    } else {
      if (result.error instanceof PLVChatroomError) {
        const err = result.error
        PLVLogger.printError(TAG, `sendEmotionImage fail`, err as Error)
        if (PLVChatroomErrorCode.USER_IS_BANNED === err.code) {
          handleSendSuccess(err.data as PLVEmotionEvent)
        } else {
          PLVToastUtils.shortShow(`speak fail: ${err.message}`)
        }
      } else {
        PLVToastUtils.shortShow(`speak fail: ${result.error.message}`)
      }
    }
  }

  private async sendLocalImage(image: string): Promise<void> {
    const result = await runCatching(this.sdk?.chatroomManager.sendLocalImage(image))
    const handleSendSuccess = (event: PLVChatImgEvent) => {
      this.fullChatListData.pushData(event)
      this.chatListScroller.scrollEdge(Edge.Bottom)
      this.isShowChatInputLayout = false
    }
    if (result.success === true) {
      handleSendSuccess(result.data)
    } else {
      if (result.error instanceof PLVChatroomError) {
        const err = result.error
        PLVLogger.printError(TAG, `sendEmotionImage fail`, err as Error)
        if (PLVChatroomErrorCode.USER_IS_BANNED === err.code) {
          handleSendSuccess(err.data as PLVChatImgEvent)
        } else {
          PLVToastUtils.shortShow(`speak fail: ${err.message}`)
        }
      } else {
        PLVToastUtils.shortShow(`speak fail: ${result.error.message}`)
      }
    }
  }

  replyText() {
    let content = this.reply?.content
    if (this.reply?.isChatImgEvent()) {
      content = '[图片]'
    } else if (this.reply?.isFileShareEvent()) {
      content = this.reply?.fileData?.name
    }
    return `${this.reply?.nick}: ${content}`
  }

  inputPlaceText() {
    return $r('app.string.plvsa_chat_input_tips_chat')
  }

  onBackPress(): boolean {
    if (this.localImagePickerVisible) {
      this.localImagePickerDialog.close()
      return true
    }
    if (this.isShowChatInputLayout) {
      this.isShowChatInputLayout = false
      return true
    }
    return false
  }

  aboutToDisappear(): void {
    this.onBackPressDisposable?.dispose()
  }

}

@Component
struct PLVSAChatEmotionLayout {
  onClickEmotionImage: (emotion: PLVEmotionImageBean) => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private emotionImages: PLVEmotionImageBean[] = []

  aboutToAppear(): void {
    this.emotionImages = this.sdk.chatroomManager.emotions ?? []
    this.sdk.chatroomManager.eventNotify.on('emotions', this.onEmotionImagesUpdate)
  }

  build() {
    Tabs({
      barPosition: BarPosition.End
    }) {
      TabContent() {
        Grid() {
          ForEach(
            this.emotionImages,
            (emotionImage: PLVEmotionImageBean) => {
              GridItem() {
                Column() {
                  Image(emotionImage.url)
                    .padding(10)
                    .objectFit(ImageFit.Contain)
                  Text(emotionImage.title)
                    .fontSize(12)
                    .fontColor('#ADADC0')
                }
                .onClick(() => this.onClickEmotionImage(emotionImage))
              }
            },
            (emotionImage: PLVEmotionImageBean) => emotionImage.id
          )
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      }
      .tabBar({
        icon: $r('app.media.plvsa_chat_emotion_image_bar_icon')
      })
    }
    .width('100%')
    .height(236)
    .barHeight(40)
    .barMode(BarMode.Scrollable)
    .backgroundColor('#2B2C35')
    .barBackgroundColor('#535353')
  }

  private onEmotionImagesUpdate = (emotions: PLVEmotionImageBean[] | undefined) => {
    this.emotionImages = emotions ?? []
  }

  aboutToDisappear(): void {
    this.sdk.chatroomManager.eventNotify.off('emotions', this.onEmotionImagesUpdate)
  }

}

@CustomDialog
struct PLVSAChatLocalImageSelectDialog {
  onSelectImage: (image: string) => void = lateInit()
  @Link localImagePickerVisible: boolean
  controller: CustomDialogController = lateInit()
  @State private readonly pickerController: PickerController = new PickerController();

  aboutToAppear(): void {
    this.localImagePickerVisible = true
  }

  build() {
    PhotoPickerComponent({
      pickerOptions: {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        selectMode: SelectMode.SINGLE_SELECT
      },
      onItemClicked: (itemInfo: ItemInfo, clickType: ClickType): boolean => {
        if (itemInfo.itemType === ItemType.CAMERA) {
          return true
        }
        return true
      },
      onSelect: (uri: string) => {
        this.onSelectImage(uri)
      },
      pickerController: this.pickerController
    })
      .width('100%')
      .height('80%')
  }

  aboutToDisappear(): void {
    this.localImagePickerVisible = false
  }

}