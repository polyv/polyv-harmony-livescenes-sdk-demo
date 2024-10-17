import {
  ChannelMenusBean,
  PLVBaseIdEvent,
  PLVChatQuoteDataBean,
  PLVChatroomError,
  PLVChatroomErrorCode,
  PLVCommonConstants,
  PLVDeviceUtils,
  PLVLazyDataSource,
  PLVLiveSceneSDK,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVLogger,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk'

const TAG = '[PLVLIChatInputView]'

@Preview
@Component
export struct PLVLIChatInputView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  chatListScroller: ListScroller = new ListScroller()
  @Link fullChatListData: PLVLazyDataSource<PLVBaseIdEvent>
  quizListScroller: ListScroller = new ListScroller()
  @Link quizListData: PLVLazyDataSource<PLVBaseIdEvent>
  @Link @Watch('onInputStatusChanged') isQuizSelected: boolean
  @Link isShowChatInputLayout: boolean
  @Link @Watch('onInputStatusChanged') isCloseRoom: boolean
  @Link @Watch('onInputStatusChanged') isFocusModeOpen: boolean
  @Link quizMenu: ChannelMenusBean | undefined
  @Link reply: PLVChatQuoteDataBean | undefined
  @LocalStorageLink('chatInputText') @Watch('onChatInputTextChanged') chatInputText: string = ''
  tempChatInputText: string = ''
  @State offsetY: number = 6 + PLVDeviceUtils.getNavigationIndicatorHeight()

  build() {
    Column() {
      if (this.reply && !this.isQuizSelected) {
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
          Image($r('app.media.plvli_chat_quote_message_close_icon'))
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
        .translate({ y: this.offsetY })
        .width(PLVCommonConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Center)
        .height(48)
        .backgroundColor('#66000000')
        .backdropBlur(8)
      }

      Row() {
        if (this.quizMenu) {
          Image(this.isQuizSelected ? $r('app.media.plvli_chat_quiz_selected') : $r('app.media.plvli_chat_quiz_default'))
            .width(36)
            .height(36)
            .padding(4)
            .margin({ right: 4 })
            .draggable(false)
            .onClick(() => {
              this.isQuizSelected = !this.isQuizSelected
            })
        }
        TextInput({ placeholder: this.inputPlaceText(), text: $$this.chatInputText })
          .height(38)
          .layoutWeight(1)
          .enterKeyType(EnterKeyType.Send)
          .onSubmit((key, event) => {
            event.keepEditableState()
            if (this.isQuizSelected) {
              this.quiz()
            } else {
              this.speak()
            }
          })
          .onAppear(() => {
            focusControl.requestFocus('chatTextInput')
          })
          .fontSize(14)
          .enabled((!this.isCloseRoom && !this.isFocusModeOpen) || this.isQuizSelected)
          .padding({ left: 16, right: 16 })
          .placeholderColor('#33ffffff')
          .fontColor('#ffffff')
          .maxLength(200)
          .maxLines(1)
          .backgroundColor('#373635')
          .borderRadius(18)
          .id('chatTextInput')
        Text($r('app.string.plvli_chat_send'))
          .padding(8)
          .margin({ left: 6 })
          .fontSize(14)
          .fontColor(this.chatInputText ? '#FFA611' : '#66F0F1F5')
          .enabled(this.chatInputText ? true : false)
          .onClick(() => {
            if (this.isQuizSelected) {
              this.quiz()
            } else {
              this.speak()
            }
          })
      }
      .onTouch((event) => {
        event.stopPropagation()
      })
      .translate({ y: this.offsetY })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(68)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#262523')
    }
    .onTouch(() => {
      this.isShowChatInputLayout = false
    })
    .justifyContent(FlexAlign.End)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  private speak() {
    if (this.chatInputText.trim().length == 0) {
      PLVToastUtils.shortShow($r('app.string.plvli_chat_toast_send_text_empty'))
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

  private quiz() {
    if (this.chatInputText.trim().length == 0) {
      PLVToastUtils.shortShow($r('app.string.plvli_chat_toast_send_text_empty'))
      return
    }
    const handleSendSuccess = (event: PLVLocalQuizEvent) => {
      this.quizListData.pushData(event)
      this.quizListScroller.scrollEdge(Edge.Bottom)
      this.isShowChatInputLayout = false
      this.chatInputText = ''
    }
    this.sdk?.chatroomManager.quiz(this.chatInputText)
      .then((event) => {
        handleSendSuccess(event)
      })
      .catch((err: PLVChatroomError) => {
        PLVLogger.printError(TAG, `quiz fail`, err as Error)
        PLVToastUtils.shortShow(`quiz fail: ${err.message}`)
      })
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
    return this.isQuizSelected ? $r('app.string.plvli_chat_input_tips_quiz') :
      this.isCloseRoom ? $r('app.string.plvli_chat_input_tips_chatroom_close') :
        this.isFocusModeOpen ? $r('app.string.plvli_chat_input_tips_focus') :
        $r('app.string.plvli_chat_input_tips_chat')
  }

  onInputStatusChanged(propName: string) {
    if ((this.isCloseRoom || this.isFocusModeOpen) && !this.isQuizSelected) {
      this.tempChatInputText = this.chatInputText
    }
    this.chatInputText = ((!this.isCloseRoom && !this.isFocusModeOpen) || this.isQuizSelected) ? this.tempChatInputText : ''
  }

  onChatInputTextChanged() {
    if ((!this.isCloseRoom && !this.isFocusModeOpen) || this.isQuizSelected) {
      this.tempChatInputText = this.chatInputText
    }
  }
}