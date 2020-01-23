FROM nvcr.io/nvidia/pytorch:19.12-py3
WORKDIR /code
RUN pip install fastai
#CMD ["/bin/bash"]
#CMD ["jupyter", "notebook", "--notebook-dir=/code"]
CMD ["jupyter", "notebook", "--notebook-dir=/code", "--NotebookApp.password='sha1:c7e6e0960789:076aa53621717f7be7eede61a95fd9772ec74784'"]