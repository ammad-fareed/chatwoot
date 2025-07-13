<script setup>
import { ref, computed, watchEffect, onUnmounted } from 'vue';
import { useToggle } from '@vueuse/core';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import axios from 'axios';

import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

const store = useStore();
const { t } = useI18n();

const currentChat = computed(() => store.getters.getSelectedChat);
const customAttributes = ref({});

const fetchCustomAttributes = async () => {
  const { data } = await axios.get(
    `/api/v1/conversations/${currentChat.value.id}/custom_attributes`
  );
  customAttributes.value = data || {};
};

watchEffect(() => {
  if (currentChat.value?.id) {
    fetchCustomAttributes();
  }
});

const isBotPaused = computed(() => customAttributes.value?.bot_paused === true);

const toggleBotStatus = async () => {
  await axios.put(
    `/api/v1/conversations/${currentChat.value.id}/custom_attributes`,
    {
      custom_attributes: {
        bot_paused: !isBotPaused.value,
      },
    }
  );

  useAlert(
    !isBotPaused.value ? 'Bot paused for this conversation' : 'Bot resumed'
  );

  await fetchCustomAttributes();
};

const [showEmailActionsModal, toggleEmailModal] = useToggle(false);
const [showActionsDropdown, toggleDropdown] = useToggle(false);

const actionMenuItems = computed(() => {
  const items = [];

  if (!currentChat.value.muted) {
    items.push({
      icon: 'i-lucide-volume-off',
      label: t('CONTACT_PANEL.MUTE_CONTACT'),
      action: 'mute',
      value: 'mute',
    });
  } else {
    items.push({
      icon: 'i-lucide-volume-1',
      label: t('CONTACT_PANEL.UNMUTE_CONTACT'),
      action: 'unmute',
      value: 'unmute',
    });
  }

  items.push({
    icon: 'i-lucide-share',
    label: t('CONTACT_PANEL.SEND_TRANSCRIPT'),
    action: 'send_transcript',
    value: 'send_transcript',
  });

  return items;
});

const handleActionClick = ({ action }) => {
  toggleDropdown(false);

  if (action === 'mute') {
    store.dispatch('muteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
  } else if (action === 'unmute') {
    store.dispatch('unmuteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
  } else if (action === 'send_transcript') {
    toggleEmailModal();
  }
};

const mute = () => {
  store.dispatch('muteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
};

const unmute = () => {
  store.dispatch('unmuteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
};

emitter.on(CMD_MUTE_CONVERSATION, mute);
emitter.on(CMD_UNMUTE_CONVERSATION, unmute);
emitter.on(CMD_SEND_TRANSCRIPT, toggleEmailModal);

onUnmounted(() => {
  emitter.off(CMD_MUTE_CONVERSATION, mute);
  emitter.off(CMD_UNMUTE_CONVERSATION, unmute);
  emitter.off(CMD_SEND_TRANSCRIPT, toggleEmailModal);
});
</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <button
      class="h-8 px-3 py-1 text-xs font-medium text-n-slate-12 border border-n-slate-300 rounded-md hover:bg-n-alpha-2 transition-colors"
      @click="toggleBotStatus"
    >
      {{ isBotPaused ? 'Resume Bot' : 'Pause Bot' }}
    </button>
    <div
      v-on-clickaway="() => toggleDropdown(false)"
      class="relative flex items-center group"
    >
      <ButtonV4
        v-tooltip="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-vertical"
        class="rounded-md group-hover:bg-n-alpha-2"
        @click="toggleDropdown()"
      />
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="actionMenuItems"
        class="mt-1 ltr:right-0 rtl:left-0 top-full"
        @action="handleActionClick"
      />
    </div>
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailModal"
    />
  </div>
</template>
